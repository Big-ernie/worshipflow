/* Big Ernie Glass Command: presentation-only enhancements. No auth or API changes. */
(()=>{'use strict';
function start(){
 const top=document.querySelector('#app .top');if(!top||document.getElementById('be-toolbox'))return;
 let dark=false;try{dark=localStorage.getItem('be-glass-theme')==='dark'}catch{}
 document.body.classList.toggle('glass-dark',dark);
 const toolbox=document.createElement('div');toolbox.className='be-tools';toolbox.id='be-toolbox';
 const switcher=document.createElement('a');switcher.className='be-switch';switcher.href='https://www.bigerniestudios.com/dashboard/';switcher.textContent='✦ Studio Command';
 switcher.title='Open the website admin (separate secure sign-in)';
 const search=document.createElement('button');search.className='be-tool';search.type='button';
 search.textContent='⌕';search.setAttribute('aria-label','Search dashboard actions');search.title='Search actions (⌘K or Ctrl+K)';
 const theme=document.createElement('button');theme.className='be-tool';theme.type='button';
 function updateTheme(){theme.textContent=document.body.classList.contains('glass-dark')?'☼':'☾';
 theme.setAttribute('aria-label',document.body.classList.contains('glass-dark')?'Enable light mode':'Enable dark mode');
 theme.title=theme.getAttribute('aria-label')}
 updateTheme();theme.addEventListener('click',()=>{const d=document.body.classList.toggle('glass-dark');try{localStorage.setItem('be-glass-theme',d?'dark':'light')}catch{}updateTheme()});
 toolbox.append(switcher,search,theme);top.insertBefore(toolbox,top.lastElementChild);
 const overlay=document.createElement('div');overlay.id='be-command';overlay.className='be-command-backdrop';overlay.hidden=true;
 const dialog=document.createElement('div');dialog.className='be-command-dialog';dialog.setAttribute('role','dialog');
 dialog.setAttribute('aria-modal','true');dialog.setAttribute('aria-label','Command search');
 const input=document.createElement('input');input.placeholder='Where would you like to go?';input.type='search';
 input.setAttribute('aria-label','Search sections and actions');
 const results=document.createElement('div');results.className='be-command-results';
 const foot=document.createElement('div');foot.className='be-command-foot';foot.textContent='Type to search · Enter to select · Esc to close';
 dialog.append(input,results,foot);overlay.append(dialog);document.body.append(overlay);
 let focusBefore=null;function close(){overlay.hidden=true;input.value='';focusBefore?.focus?.()}
 function commands(){
  const entries=[...document.querySelectorAll('#nav button')].filter(b=>b.textContent.trim()&&b.offsetParent!==null)
   .map(b=>({name:b.textContent.trim(),category:'CRM Hub',action:()=>b.click()}));
  entries.push({name:'Studio Command · Website editor',category:'Switch application',action:()=>{window.location.href='https://www.bigerniestudios.com/dashboard/'}});
  return entries;
 }
 function render(){
  const q=input.value.trim().toLowerCase(), matches=commands().filter(c=>c.name.toLowerCase().includes(q)||c.category.toLowerCase().includes(q)).slice(0,15);
  results.replaceChildren();
  if(!matches.length){const p=document.createElement('p');p.textContent='No matching actions found.';results.append(p);return}
  matches.forEach((c,i)=>{const b=document.createElement('button');b.type='button';
   const name=document.createElement('span');name.textContent=c.name;
   const category=document.createElement('small');category.textContent=c.category;b.append(name,category);
   b.addEventListener('click',()=>{close();c.action()});results.append(b);
  });
 }
 function open(){focusBefore=document.activeElement;overlay.hidden=false;render();input.focus()}
 search.addEventListener('click',open);input.addEventListener('input',render);
 input.addEventListener('keydown',e=>{if(e.key==='Enter'){const first=results.querySelector('button');if(first){e.preventDefault();first.click()}}});
 overlay.addEventListener('click',e=>{if(e.target===overlay)close()});
 document.addEventListener('keydown',e=>{
  if((e.ctrlKey||e.metaKey)&&e.key.toLowerCase()==='k'){e.preventDefault();overlay.hidden?open():close()}
  if(e.key==='Escape'&&!overlay.hidden){e.preventDefault();close()}
 });
}
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',start,{once:true});else start();
})();