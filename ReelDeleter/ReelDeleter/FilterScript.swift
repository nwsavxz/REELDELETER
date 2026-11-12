import Foundation

/// The JavaScript that runs inside Instagram's page (in an isolated content world,
/// so Instagram's own scripts can't see or tamper with it).
///
/// `FilterSettings.makeUserScript()` prepends `var RD_CONFIG = {...};` before this runs.
///
/// It matches on URL paths (`/reels/`, `/reel/<id>`, `/<user>/reels/`, `/explore/`),
/// not on Instagram's generated class names, because paths change far less often.
/// If something stops working, open Safari's Web Inspector on the app and check the
/// console for lines starting with "[reel-deleter]".
enum FilterScript {
    static let source = #"""
(() => {
  'use strict';
  if (window.__rdInstalled) return;
  window.__rdInstalled = true;

  const cfg = (typeof RD_CONFIG === 'object' && RD_CONFIG) || {};
  // Test hook: the page can't set this, because it lives in the isolated world.
  const nav = window.__rdNav || {
    back: () => history.back(),
    replace: (u) => location.replace(u),
  };
  const log = (...a) => { if (cfg.debug) console.log('[reel-deleter]', ...a); };
  const HIDE = 'data-rd-hidden';

  // ---- path helpers -------------------------------------------------------
  const norm = (p) => (p.length > 1 && p.endsWith('/')) ? p.slice(0, -1) : p;
  const under = (p, base) => p === base || p.startsWith(base + '/');
  const pathOf = (href) => {
    try {
      const u = new URL(href, location.href);
      return u.host === location.host ? norm(u.pathname) : null;
    } catch (e) { return null; }
  };

  // ---- what counts as a Reels / Explore page ------------------------------
  const isReelsTab = (p) => p === '/reels' || /^\/[^/]+\/reels$/.test(p);
  const isExploreTab = (p) => p === '/explore';
  const isSingleReel = (p) => /^\/reels?\/[^/]+$/.test(p);
  const isBlocked = (p) => {
    if (cfg.blockReels &&
        (under(p, '/reels') || p.startsWith('/reel/') || /^\/[^/]+\/reels(\/|$)/.test(p))) return true;
    if (cfg.hideExplore && under(p, '/explore')) return true;
    return false;
  };

  // ---- layer 1: CSS, so tabs are hidden as early as possible ---------------
  const css = [];
  if (cfg.hideReelsTab) {
    css.push('a[href="/reels/"],a[href="/reels"],a[href$="/reels/"]{display:none!important}');
  }
  if (cfg.hideExplore) {
    css.push('a[href="/explore/"],a[href="/explore"]{display:none!important}');
  }
  css.push('[' + HIDE + ']{display:none!important}');
  if (cfg.customCSS) css.push(String(cfg.customCSS));

  let styleEl = null;
  const ensureStyle = () => {
    if (styleEl && styleEl.isConnected) return;
    styleEl = document.createElement('style');
    styleEl.id = 'rd-style';
    styleEl.textContent = css.join('\n');
    (document.head || document.documentElement).appendChild(styleEl);
  };

  // ---- layer 2: hide the whole tab item, not just the link inside it -------
  const hide = (el) => {
    el.setAttribute(HIDE, '');
    el.style.setProperty('display', 'none', 'important'); // survives a page CSP
  };
  const hideTabItem = (a) => {
    let el = a;
    // Climb while the parent holds no other links, so the item's wrapper goes
    // too and no empty gap is left in the bar. Capped at 5 levels.
    for (let i = 0; i < 5; i++) {
      const parent = el.parentElement;
      if (!parent || parent === document.body || parent === document.documentElement) break;
      if (parent.querySelectorAll('a[href]').length > 1) break;
      el = parent;
    }
    hide(el);
    log('hid tab item', a.getAttribute('href'));
  };
  const scan = () => {
    if (!cfg.hideReelsTab && !cfg.hideExplore) return;
    const links = document.querySelectorAll('a[href*="/reels"], a[href*="/explore"]');
    for (const a of links) {
      if (a.hasAttribute(HIDE) || a.closest('[' + HIDE + ']')) continue;
      const p = pathOf(a.getAttribute('href'));
      if (p === null) continue;
      if ((cfg.hideReelsTab && isReelsTab(p)) || (cfg.hideExplore && isExploreTab(p))) hideTabItem(a);
    }
  };

  // ---- layer 3: stop navigation to blocked pages ---------------------------
  let allowed = null;      // a Reel opened on purpose from a DM
  let cooldownUntil = 0;
  let redirects = [];

  document.addEventListener('click', (e) => {
    const a = e.target && e.target.closest ? e.target.closest('a[href]') : null;
    if (!a) return;
    const p = pathOf(a.getAttribute('href'));
    if (p === null || !isBlocked(p)) return;
    if (cfg.allowDMReels && isSingleReel(p) && under(norm(location.pathname), '/direct')) {
      allowed = { path: p, arrived: false, at: Date.now() };
      return;
    }
    e.preventDefault();
    e.stopPropagation();
    e.stopImmediatePropagation();
    log('blocked click', p);
  }, true);

  const guardRoute = () => {
    const p = norm(location.pathname);
    if (allowed) {
      if (p === allowed.path) allowed.arrived = true;
      else if (allowed.arrived || Date.now() - allowed.at > 5000) allowed = null;
    }
    if (!isBlocked(p) || (allowed && p === allowed.path)) return;
    const now = Date.now();
    if (now < cooldownUntil) return;
    cooldownUntil = now + 800;
    redirects = redirects.filter((t) => now - t < 4000);
    redirects.push(now);
    log('blocked route', p);
    if (redirects.length > 2 || history.length <= 1) nav.replace('/');
    else nav.back();
  };

  // ---- wiring ---------------------------------------------------------------
  let timer = 0;
  const tick = () => { timer = 0; ensureStyle(); scan(); guardRoute(); };
  const schedule = () => { if (!timer) timer = setTimeout(tick, 120); };

  ensureStyle();
  guardRoute(); // a deep link to a blocked page leaves before it paints
  new MutationObserver(schedule).observe(document, { childList: true, subtree: true });
  window.addEventListener('popstate', schedule);
  window.addEventListener('hashchange', schedule);
  setInterval(guardRoute, 500);
  schedule();
})();
"""#
}
