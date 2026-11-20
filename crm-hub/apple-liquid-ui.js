/* Big Ernie CRM Hub: local, presentation-only navigation polish.
   Icons use open-line, 24x24 stroke SVG conventions. No backend changes. */
(() => {
  "use strict";
  const shapes = {
    dashboard: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
    contacts: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
    companies: '<rect x="4" y="2" width="16" height="20" rx="2"/><path d="M9 7h1m4 0h1M9 11h1m4 0h1M9 15h1m4 0h1M10 22v-3h4v3"/>',
    deals: '<path d="M4.7 10.6 2 12l4 7h4l2.2-2.2"/><path d="m19.3 10.6 2.7 1.4-4 7h-4l-2.2-2.2"/><path d="M7.8 9.1 11 6h2l4 3-3.3 3-2.2-1.3-2.1 2.1"/><path d="m2 9 4.5-3h4.5m11 3-4.5-3H14"/>',
    quotes: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z"/><path d="M14 2v6h6M8 13h8M8 17h6"/>',
    followups: '<rect x="4" y="3" width="16" height="18" rx="3"/><path d="m8 12 2.5 2.5L16 9"/>',
    appointments: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',
    whatsapp: '<path d="M21 11.5a8.5 8.5 0 0 1-12.4 7.5L3 21l2-5.6A8.5 8.5 0 1 1 21 11.5Z"/><path d="M8.7 9c.8 3 3.1 5.2 6.2 6.1l1.4-1.3"/>',
    products_services: '<path d="m12 2 9 5v10l-9 5-9-5V7l9-5Z"/><path d="m3 7 9 5 9-5M12 12v10"/>',
    reports: '<path d="M4 20V10M10 20V4M16 20v-9M22 20v-6M2 21h21"/>',
    activities: '<path d="M3 12h4l3-6 4 12 3-6h4"/>',
    team: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9M16 3.2a4 4 0 0 1 0 7.6"/>',
    settings: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-2.86 2.86-.06-.06A1.7 1.7 0 0 0 15 19.4a1.7 1.7 0 0 0-1.5 1.6V22h-4v-1a1.7 1.7 0 0 0-1.5-1.6A1.7 1.7 0 0 0 6.1 19.74l-.06.06-2.86-2.86.06-.06A1.7 1.7 0 0 0 3.6 15 1.7 1.7 0 0 0 2 13.5h-1v-3h1A1.7 1.7 0 0 0 3.6 9a1.7 1.7 0 0 0-.36-1.88l-.06-.06L6.04 4.2l.06.06A1.7 1.7 0 0 0 8 4.6 1.7 1.7 0 0 0 9.5 3V2h4v1A1.7 1.7 0 0 0 15 4.6a1.7 1.7 0 0 0 1.88-.34l.06-.06 2.86 2.86-.06.06A1.7 1.7 0 0 0 19.4 9 1.7 1.7 0 0 0 21 10.5h1v3h-1a1.7 1.7 0 0 0-1.6 1.5Z" transform="translate(0 .2) scale(.96)"/>',
    platform: '<path d="M3 7 12 2l9 5v10l-9 5-9-5V7Z"/><path d="M3 7l9 5 9-5M12 12v10"/>'
  };
  function enhanceNavigation() {
    const nav = document.getElementById("nav");
    if (!nav) return;
    for (const button of nav.querySelectorAll("button[data-v]")) {
      if (button.querySelector(".be-nav-glyph")) continue;
      const kind = button.dataset.v;
      const icon = document.createElement("span");
      icon.className = "be-nav-glyph";
      icon.setAttribute("aria-hidden", "true");
      icon.innerHTML = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" focusable="false">' + (shapes[kind] || shapes.dashboard) + "</svg>";
      button.prepend(icon);
    }
  }
  function init() {
    const nav = document.getElementById("nav");
    if (!nav) return;
    enhanceNavigation();
    new MutationObserver(enhanceNavigation).observe(nav,{childList:true});
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded",init,{once:true});
  else init();
})();