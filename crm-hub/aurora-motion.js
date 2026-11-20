/* Big Ernie CRM Hub: decorative aurora motion, zero application dependencies. */
(() => {
 "use strict";
 function start(){
  if(document.getElementById("be-aurora-layer"))return;
  const layer=document.createElement("div");
  layer.id="be-aurora-layer";
  layer.setAttribute("aria-hidden","true");
  const pan=document.createElement("div");pan.className="be-aurora-pan";
  const image=document.createElement("div");image.className="be-aurora-image";
  pan.append(image);
  const shade=document.createElement("div");shade.className="be-aurora-shade";
  layer.append(pan,shade);
  document.body.prepend(layer);
  const auth=document.getElementById("auth");
  function updateAuthState(){
   document.body.classList.toggle("be-auth-visible",Boolean(auth&&!auth.classList.contains("hidden")));
  }
  updateAuthState();
  if(auth)new MutationObserver(updateAuthState).observe(auth,{attributes:true,attributeFilter:["class"]});
  const reduced=window.matchMedia("(prefers-reduced-motion: reduce)");
  let raf=0;
  function paint(){
    raf=0;
    if(reduced.matches){layer.style.removeProperty("--be-parallax-y");return}
    const y=Math.max(0,window.scrollY||document.documentElement.scrollTop||document.body.scrollTop||0);
    const shift=Math.min(125,Math.round(y*.085));
    layer.style.setProperty("--be-parallax-y",(-shift)+"px");
  }
  function requestPaint(){if(!raf)raf=requestAnimationFrame(paint)}
  window.addEventListener("scroll",requestPaint,{passive:true});
  window.addEventListener("resize",requestPaint,{passive:true});
  if(reduced.addEventListener)reduced.addEventListener("change",requestPaint);
  requestPaint();
 }
 if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",start,{once:true});
 else start();
})();