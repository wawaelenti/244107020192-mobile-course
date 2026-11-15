import {connectPage,sleep} from './capture_web_evidence.mjs';
const c=await connectPage();
c.on('Runtime.consoleAPICalled',p=>console.log('console',p.type,p.args.map(x=>x.value??x.description)));
c.on('Runtime.exceptionThrown',p=>console.log('exception',JSON.stringify(p)));
await c.send('Runtime.enable');
console.log(await c.eval('({status:document.body.getAttribute("data-week11"),raf:window.__week11raf?.length,lastResult:localStorage.getItem("week11.result"),marks:performance.getEntriesByType("mark").map(m=>({name:m.name,time:m.startTime})),hidden:document.hidden})'));
try{await c.send('Tracing.end')}catch(e){console.log(e.message)};
await sleep(1000);c.close();
