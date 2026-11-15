import {connectPage} from './capture_web_evidence.mjs';
const c=await connectPage();
console.log(await c.eval('({url:location.href,state:document.body?.getAttribute("data-week11"),text:document.body?.innerText,html:document.body?.innerHTML.slice(0,1200)})'));
await c.send('Page.enable'); await c.screenshot('chrome-diagnostic.png');c.close();
