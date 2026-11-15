import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const out = path.join(root, 'screenshots');
export class CDP {
  constructor(url) {
    this.ws = new WebSocket(url); this.id = 0; this.pending = new Map(); this.handlers = new Map();
    this.ready = new Promise((resolve, reject) => { this.ws.addEventListener('open', resolve, {once:true}); this.ws.addEventListener('error', reject, {once:true}); });
    this.ws.addEventListener('message', ({data}) => {
      const msg = JSON.parse(data);
      if (msg.id) { const p = this.pending.get(msg.id); this.pending.delete(msg.id); if (p) msg.error ? p.reject(new Error(JSON.stringify(msg.error))) : p.resolve(msg.result); }
      else for (const fn of this.handlers.get(msg.method) || []) fn(msg.params);
    });
  }
  on(name, fn) { const list = this.handlers.get(name) || []; list.push(fn); this.handlers.set(name, list); return () => this.handlers.set(name, list.filter(f => f !== fn)); }
  async send(method, params={}) { await this.ready; const id = ++this.id; const p = new Promise((resolve,reject) => this.pending.set(id,{resolve,reject})); this.ws.send(JSON.stringify({id,method,params})); return p; }
  async eval(expression) { const r = await this.send('Runtime.evaluate',{expression,awaitPromise:true,returnByValue:true}); if(r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails)); return r.result.value; }
  async screenshot(name) { const r = await this.send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false}); fs.writeFileSync(path.join(out,name),Buffer.from(r.data,'base64')); }
  close() { this.ws.close(); }
}
export const sleep = ms => new Promise(r => setTimeout(r,ms));
export async function waitFor(c, expr, seconds=90) { const until = Date.now()+seconds*1000; while(Date.now()<until){ if(await c.eval(expr)) return; await sleep(250); } throw Error('Timeout: '+expr); }
export async function connectPage() { const pages = await (await fetch('http://127.0.0.1:9222/json/list')).json(); const target=pages.find(p=>p.type==='page' && p.url.includes(':5111')); if(!target) throw Error(JSON.stringify(pages)); return new CDP(target.webSocketDebuggerUrl); }
async function heap(c,name) {
  await c.send('HeapProfiler.collectGarbage');
  const usage = await c.send('Runtime.getHeapUsage');
  const chunks=[]; const off=c.on('HeapProfiler.addHeapSnapshotChunk', p=>chunks.push(p.chunk));
  await c.send('HeapProfiler.takeHeapSnapshot',{reportProgress:false,captureNumericValue:true}); off();
  fs.writeFileSync(path.join(out,name+'.heapsnapshot.gz'),zlib.gzipSync(chunks.join('')));
  return usage;
}
async function trace(c, run) {
  await c.send('Tracing.start',{categories:'devtools.timeline,disabled-by-default-devtools.timeline,disabled-by-default-devtools.timeline.frame,blink.user_timing,v8,disabled-by-default-v8.cpu_profiler',options:'sampling-frequency=10000',transferMode:'ReturnAsStream'});
  await run();
  const complete=new Promise(resolve=>{const off=c.on('Tracing.tracingComplete',p=>{off();resolve(p);});});
  await c.send('Tracing.end'); const {stream}=await complete; let data='';
  while(true){const chunk=await c.send('IO.read',{handle:stream}); data+=chunk.base64Encoded?Buffer.from(chunk.data,'base64').toString():chunk.data; if(chunk.eof) break;}
  await c.send('IO.close',{handle:stream}); return data;
}
async function main(){
  fs.mkdirSync(out,{recursive:true}); const c=await connectPage();
  await c.send('Page.enable'); await c.send('Runtime.enable');
  await c.send('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false});
  const errors=[];c.on('Runtime.exceptionThrown',p=>errors.push(p.exceptionDetails));
  const summary={date:new Date().toISOString(), browser:await c.send('Browser.getVersion'), viewport:{width:1440,height:1000,dpr:1},variants:{}};
  for(const variant of ['before','after']){
    const repetitions=[];
    for(let run=1;run<=3;run++){
      await c.send('Page.navigate',{url:`http://localhost:5111/?variant=${variant}`});
      await waitFor(c,"document.body?.getAttribute('data-week11') === 'ready'");
      await sleep(1500);
      // Warm up shader/layout and repository using the identical scenario.
      await c.eval("window.dispatchEvent(new Event('week11-run'))");
      await waitFor(c,"document.body.getAttribute('data-week11') === 'done'");
      const traceData=await trace(c,async()=>{
        await c.eval(`window.__week11raf=[]; window.__week11stop=false; (()=>{let last;function tick(t){if(last!==undefined)window.__week11raf.push(t-last);last=t;if(!window.__week11stop)requestAnimationFrame(tick);}requestAnimationFrame(tick);})(); window.dispatchEvent(new Event('week11-run'));`);
        await waitFor(c,"document.body.getAttribute('data-week11') === 'done'");
        await c.eval('window.__week11stop=true');
      });
      const result=await c.eval("({...JSON.parse(localStorage.getItem('week11.result')),raf:window.__week11raf})");
      fs.writeFileSync(path.join(out,`${variant}-run-${run}.trace.json.gz`),zlib.gzipSync(traceData));
      repetitions.push(result);
      if(run===3){
        await c.screenshot(`${variant}-app.png`);
        const initial=await heap(c,`${variant}-memory-before`);
        await c.eval("window.dispatchEvent(new Event('week11-memory'))");
        await waitFor(c,"document.body.getAttribute('data-week11') === 'memory-done'");
        const final=await heap(c,`${variant}-memory-after`);
        summary.variants[variant]={repetitions,heapBefore:initial,heapAfter:final};
      }
      console.log(`${variant} run ${run}: ${result.sourceReadsFor20Calls} reads; ${result.repository20CallsMs} ms; ${result.raf.length} rAF samples`);
    }
  }
  summary.runtimeExceptions=errors;fs.writeFileSync(path.join(out,'web-metrics.json'),JSON.stringify(summary,null,2));c.close();
}
if(process.argv[1] && path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) main().catch(e=>{console.error(e);process.exitCode=1;});
