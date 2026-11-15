import {connectPage} from './capture_web_evidence.mjs';
const c=await connectPage();console.log(await c.eval("fetch('/main.dart.js').then(r=>r.text()).then(s=>s.split('\\n').slice(73184,73208).join('\\n'))"));c.close();
