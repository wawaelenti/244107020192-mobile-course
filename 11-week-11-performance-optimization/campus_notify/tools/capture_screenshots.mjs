import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import {connectPage,sleep,waitFor,out} from './capture_web_evidence.mjs';
const c=await connectPage();await c.send('Page.enable');await c.send('Runtime.enable');
await c.send('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false});
try{await c.send('Tracing.end')}catch{}; const errors=[];c.on('Runtime.exceptionThrown',p=>errors.push(p.exceptionDetails));
try {
for(const variant of ['before','after']){
 await c.send('Page.navigate',{url:`http://localhost:5111/?variant=${variant}`});
 await waitFor(c,"document.body?.getAttribute('data-week11') === 'ready'");await sleep(1200); await c.eval('window.__originalMeasure=performance.measure.bind(performance); performance.measure=(name,...args)=>name===\"week11:scenario\"?undefined:window.__originalMeasure(name,...args)');
 await c.screenshot(`${variant}-app.png`);
 await c.send('Tracing.start',{categories:'devtools.timeline,disabled-by-default-devtools.timeline,disabled-by-default-devtools.timeline.frame,blink.user_timing,v8',transferMode:'ReturnAsStream'});
 await c.eval("window.dispatchEvent(new Event('week11-run'))");
 await waitFor(c,"document.body.getAttribute('data-week11') === 'done'",30);
 const complete=new Promise(resolve=>{const off=c.on('Tracing.tracingComplete',p=>{off();resolve(p);});});await c.send('Tracing.end');const {stream}=await complete;
 let data='';while(true){const chunk=await c.send('IO.read',{handle:stream});data+=chunk.data;if(chunk.eof)break;}await c.send('IO.close',{handle:stream});
 fs.writeFileSync(path.join(out,`${variant}-run-1.trace.json.gz`),zlib.gzipSync(data));
 fs.writeFileSync(path.join(out,`${variant}-result.json`),JSON.stringify(await c.eval("JSON.parse(localStorage.getItem('week11.result'))"),null,2));
 await sleep(300);await c.screenshot(`${variant}-app.png`);console.log(variant,'captured');
}
console.log('errors',JSON.stringify(errors));
} finally {c.close();}

