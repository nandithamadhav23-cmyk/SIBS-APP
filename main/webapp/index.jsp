<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="com.DAO.UserDAO" %>
<%
    UserDAO dao = new UserDAO();
    boolean adminExists = dao.checkIfAdminExists();
    String role = (session != null) ? (String) session.getAttribute("role") : null;
    String error = (request.getAttribute("error") != null) ? (String) request.getAttribute("error") : "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SIBS — Smart Inventory & Billing System</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Clash+Display:wght@400;500;600;700&family=Bricolage+Grotesque:opsz,wght@12..96,300;12..96,400;12..96,500;12..96,600;12..96,700;12..96,800&family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,500;1,300&display=swap" rel="stylesheet">
<style>
/* ══ TOKENS ════════════════════════════════════════════════════════ */
:root {
  /* Warm-to-violet palette — vivid, never dull */
  --rose:       #f43f5e;
  --rose-d:     #e11d48;
  --rose-l:     #fff1f2;
  --rose-mid:   #fda4af;
  --amber:      #f97316;
  --amber-l:    #fff7ed;
  --amber-mid:  #fdba74;
  --violet:     #7c3aed;
  --violet-d:   #6d28d9;
  --violet-l:   #f5f3ff;
  --violet-mid: #c4b5fd;
  --coral:      #fb923c;
  --fuchsia:    #d946ef;
  --emerald:    #10b981;
  --sky-blue:   #0ea5e9;
  --gold:       #eab308;

  /* Surfaces */
  --bg:         #fdf6f0;
  --bg-2:       #fff8f3;
  --surface:    #ffffff;
  --border:     #fde8d8;
  --border-2:   #e8d5f0;

  /* Text */
  --ink:        #1c0a00;
  --ink-2:      #3d1f0f;
  --muted:      #8b6656;
  --light:      #c49a84;

  /* Gradients */
  --grad-hero:  linear-gradient(135deg, #fdf6f0 0%, #fef2f8 50%, #f5f3ff 100%);
  --grad-brand: linear-gradient(135deg, var(--rose) 0%, var(--amber) 60%, var(--coral) 100%);
  --grad-violet:linear-gradient(135deg, var(--violet) 0%, var(--fuchsia) 100%);
  --grad-warm:  linear-gradient(135deg, var(--amber) 0%, var(--rose) 100%);
  --grad-card:  linear-gradient(160deg, #fff8f3 0%, #fdf2fe 100%);

  /* Shadows */
  --shadow-sm:  0 1px 4px rgba(244,63,94,.06), 0 4px 16px rgba(124,58,237,.06);
  --shadow-md:  0 4px 16px rgba(244,63,94,.10), 0 12px 40px rgba(124,58,237,.10);
  --shadow-rose:0 8px 32px rgba(244,63,94,.28);
  --shadow-vio: 0 8px 32px rgba(124,58,237,.25);

  --radius:     14px;
  --radius-lg:  22px;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html { scroll-behavior: smooth; }
body {
  font-family: 'Plus Jakarta Sans', sans-serif;
  background: var(--bg);
  color: var(--ink);
  overflow-x: hidden;
}

/* ══ SCROLLBAR ═══════════════════════════════════════════════════ */
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: var(--bg); }
::-webkit-scrollbar-thumb {
  background: linear-gradient(180deg, var(--rose), var(--violet));
  border-radius: 6px;
}

/* ══ GLOBAL TEXTURE OVERLAY ══════════════════════════════════════ */
body::before {
  content: '';
  position: fixed; inset: 0; z-index: 0; pointer-events: none;
  background-image:
    url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23f43f5e' fill-opacity='0.025'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
  opacity: 1;
}

/* ══ NAVBAR ══════════════════════════════════════════════════════ */
.navbar {
  position: fixed; top: 0; left: 0; right: 0; z-index: 1000;
  background: rgba(253,246,240,.90);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border-bottom: 1px solid rgba(244,63,94,.12);
  padding: .7rem 0;
  transition: all .3s;
}
.navbar.scrolled {
  box-shadow: 0 2px 28px rgba(244,63,94,.12);
}
.nav-brand {
  font-family: 'Clash Display', 'Bricolage Grotesque', sans-serif;
  font-size: 1.2rem; font-weight: 700;
  color: var(--ink); text-decoration: none;
  display: flex; align-items: center; gap: .55rem;
  letter-spacing: -.2px;
}
.brand-icon {
  width: 34px; height: 34px; border-radius: 10px;
  background: var(--grad-brand);
  display: flex; align-items: center; justify-content: center;
  color: #fff; font-size: .88rem;
  box-shadow: var(--shadow-rose);
}
.brand-dot { background: var(--grad-brand); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.nav-pill {
  display: inline-flex; align-items: center; gap: .4rem;
  padding: .44rem 1.05rem; border-radius: 30px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: .81rem; font-weight: 500;
  text-decoration: none; cursor: pointer; transition: all .2s; border: none;
  white-space: nowrap;
}
.nav-pill-ghost {
  color: var(--ink-2); background: transparent;
  border: 1px solid var(--border);
}
.nav-pill-ghost:hover {
  background: var(--rose-l); border-color: rgba(244,63,94,.3);
  color: var(--rose);
}
.nav-pill-brand {
  color: #fff;
  background: var(--grad-brand);
  box-shadow: var(--shadow-rose);
}
.nav-pill-brand:hover { opacity: .92; transform: translateY(-1px); }
.nav-pill-ghost-vio {
  color: var(--violet); background: transparent;
  border: 1px solid rgba(124,58,237,.25);
}
.nav-pill-ghost-vio:hover { background: var(--violet-l); }

/* hamburger */
.hamburger { display: none; }
@media(max-width:768px) {
  .nav-links { display: none; }
  .hamburger {
    display: flex; flex-direction: column; gap: 4px;
    background: none; border: none; cursor: pointer; padding: .4rem;
  }
  .hamburger span {
    display: block; width: 22px; height: 2px;
    background: var(--ink); border-radius: 2px; transition: all .25s;
  }
  .nav-mobile-open .hamburger span:nth-child(1) { transform: translateY(6px) rotate(45deg); }
  .nav-mobile-open .hamburger span:nth-child(2) { opacity: 0; }
  .nav-mobile-open .hamburger span:nth-child(3) { transform: translateY(-6px) rotate(-45deg); }
  .nav-links.open {
    display: flex; flex-direction: column; align-items: stretch;
    position: absolute; top: 100%; left: 0; right: 0;
    background: rgba(253,246,240,.97); border-bottom: 1px solid var(--border);
    padding: 1rem; gap: .5rem;
    box-shadow: 0 8px 24px rgba(244,63,94,.1);
  }
}

/* ══ HERO ════════════════════════════════════════════════════════ */
.hero {
  min-height: 100vh;
  padding: 120px 0 80px;
  display: flex; align-items: center;
  position: relative; overflow: hidden;
  background: var(--grad-hero);
}
/* Layered radial meshes */
.hero::before {
  content: '';
  position: absolute; inset: 0;
  background:
    radial-gradient(ellipse 70% 55% at 8% 18%, rgba(244,63,94,.11) 0%, transparent 60%),
    radial-gradient(ellipse 55% 50% at 92% 75%, rgba(124,58,237,.10) 0%, transparent 60%),
    radial-gradient(ellipse 50% 40% at 55% 55%, rgba(249,115,22,.07) 0%, transparent 60%),
    radial-gradient(ellipse 35% 30% at 75% 15%, rgba(217,70,239,.08) 0%, transparent 55%);
}
/* Dot grid */
.hero::after {
  content: '';
  position: absolute; inset: 0;
  background-image: radial-gradient(circle, rgba(244,63,94,.14) 1px, transparent 1px);
  background-size: 30px 30px;
  mask-image: radial-gradient(ellipse 85% 85% at 50% 50%, black 30%, transparent 100%);
  -webkit-mask-image: radial-gradient(ellipse 85% 85% at 50% 50%, black 30%, transparent 100%);
}
.hero-content { position: relative; z-index: 1; }

/* eyebrow */
.eyebrow {
  display: inline-flex; align-items: center; gap: .5rem;
  background: linear-gradient(135deg, rgba(244,63,94,.1), rgba(124,58,237,.1));
  color: var(--rose-d);
  border: 1px solid rgba(244,63,94,.22);
  border-radius: 30px; padding: .35rem 1rem;
  font-size: .73rem; font-weight: 700; letter-spacing: .6px;
  text-transform: uppercase; margin-bottom: 1.5rem;
}
.eyebrow .dot {
  width: 7px; height: 7px; border-radius: 50%;
  background: var(--grad-brand);
  animation: pulse-dot 1.8s ease infinite;
}
@keyframes pulse-dot {
  0%,100% { opacity: 1; transform: scale(1); }
  50% { opacity: .5; transform: scale(.7); }
}
.hero-title {
  font-family: 'Clash Display', 'Bricolage Grotesque', sans-serif;
  font-size: clamp(2.4rem, 5vw, 3.9rem);
  font-weight: 700; line-height: 1.1;
  letter-spacing: -.4px; color: var(--ink);
  margin-bottom: 1.25rem;
}
.hero-title .gradient-text {
  background: var(--grad-brand);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
.hero-sub {
  font-size: 1.02rem; color: var(--muted); line-height: 1.78;
  max-width: 500px; margin-bottom: 2.5rem; font-weight: 300;
}
.hero-cta { display: flex; gap: .75rem; flex-wrap: wrap; }
.btn-primary-lg {
  display: inline-flex; align-items: center; gap: .5rem;
  padding: .82rem 1.85rem; border-radius: 12px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: .9rem; font-weight: 600;
  text-decoration: none; cursor: pointer; border: none;
  background: var(--grad-brand);
  color: #fff; box-shadow: var(--shadow-rose);
  transition: all .25s;
}
.btn-primary-lg:hover { opacity: .92; transform: translateY(-2px); color: #fff; box-shadow: 0 14px 44px rgba(244,63,94,.35); }
.btn-secondary-lg {
  display: inline-flex; align-items: center; gap: .5rem;
  padding: .82rem 1.85rem; border-radius: 12px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: .9rem; font-weight: 500;
  text-decoration: none; cursor: pointer;
  background: var(--surface); color: var(--ink);
  border: 1px solid var(--border); box-shadow: var(--shadow-sm);
  transition: all .25s;
}
.btn-secondary-lg:hover { background: var(--rose-l); border-color: rgba(244,63,94,.3); color: var(--rose-d); transform: translateY(-2px); }

/* trust strip */
.trust-strip {
  display: flex; align-items: center; gap: 1.5rem; margin-top: 2.5rem; flex-wrap: wrap;
}
.trust-item {
  display: flex; align-items: center; gap: .4rem;
  font-size: .78rem; color: var(--muted); font-weight: 500;
}
.trust-item i { color: var(--emerald); font-size: .9rem; }
.trust-sep { color: var(--border); }

/* ── HERO VISUAL ── */
.hero-visual { position: relative; padding: 1rem; }
.dashboard-mockup {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 20px;
  box-shadow: var(--shadow-md);
  overflow: hidden; position: relative;
}
.mockup-topbar {
  background: linear-gradient(135deg, var(--rose-d) 0%, var(--violet) 100%);
  padding: .7rem 1rem; display: flex; align-items: center; gap: .5rem;
}
.mockup-dot { width: 10px; height: 10px; border-radius: 50%; }
.mockup-title {
  margin-left: .5rem; font-family: 'Clash Display', sans-serif;
  font-size: .7rem; font-weight: 600; color: rgba(255,255,255,.75);
}
.mockup-body { padding: 1rem; background: linear-gradient(135deg, #fff8f3 0%, #fdf2fe 100%); }
.mockup-stat-row { display: grid; grid-template-columns: repeat(3,1fr); gap: .5rem; margin-bottom: .75rem; }
.mockup-stat {
  background: var(--surface); border-radius: 10px; padding: .6rem .7rem;
  border: 1px solid var(--border);
}
.mockup-stat-num { font-family: 'Clash Display', sans-serif; font-weight: 700; font-size: .85rem; color: var(--ink); }
.mockup-stat-lbl { font-size: .6rem; color: var(--light); margin-top: 1px; }
.mockup-stat-badge {
  display: inline-block; font-size: .55rem; font-weight: 700;
  padding: 1px 5px; border-radius: 4px; margin-left: 3px;
}
.badge-green { background: rgba(16,185,129,.12); color: var(--emerald); }
.badge-red   { background: rgba(244,63,94,.12);  color: var(--rose); }
.mockup-chart {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; padding: .7rem; margin-bottom: .5rem;
}
.mockup-chart-title { font-size: .65rem; font-weight: 600; color: var(--ink-2); margin-bottom: .5rem; }
.mockup-bars { display: flex; align-items: flex-end; gap: .3rem; height: 52px; }
.mockup-bar {
  flex: 1; border-radius: 4px 4px 0 0;
  background: var(--grad-brand);
  opacity: .8; animation: bar-grow .8s ease both;
}
@keyframes bar-grow { from { height: 0 !important; } }
.mockup-row-items { display: grid; grid-template-columns: 1fr 1fr; gap: .5rem; }
.mockup-list-card {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; padding: .6rem .7rem;
}
.mockup-list-title { font-size: .6rem; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .5px; margin-bottom: .4rem; }
.mockup-list-item {
  display: flex; align-items: center; justify-content: space-between;
  font-size: .58rem; color: var(--ink-2); padding: 2px 0;
  border-bottom: 1px solid var(--border);
}
.mockup-list-item:last-child { border: none; }

/* Floating badges */
.float-badge {
  position: absolute; background: var(--surface);
  border: 1px solid var(--border); border-radius: 12px;
  padding: .5rem .85rem; box-shadow: var(--shadow-md);
  display: flex; align-items: center; gap: .45rem;
  font-size: .75rem; font-weight: 600; color: var(--ink);
  animation: float-anim 4s ease-in-out infinite;
  white-space: nowrap;
}
@keyframes float-anim {
  0%,100% { transform: translateY(0); }
  50%      { transform: translateY(-8px); }
}
.badge-1 { top: -16px; right: 30px; animation-delay: 0s; }
.badge-2 { bottom: 20px; left: -16px; animation-delay: 1.5s; }
.badge-icon { font-size: .9rem; }

/* ══ STATS ═══════════════════════════════════════════════════════ */
.stats-section {
  background: var(--surface);
  border-top: 1px solid var(--border);
  border-bottom: 1px solid var(--border);
  padding: 2.5rem 0;
}
.stats-inner {
  display: grid; grid-template-columns: repeat(4,1fr); gap: 0;
}
@media(max-width:768px) { .stats-inner { grid-template-columns: repeat(2,1fr); } }
.stat-box {
  text-align: center; padding: 1.5rem 1rem;
  border-right: 1px solid var(--border);
  position: relative; overflow: hidden;
}
.stat-box:last-child { border-right: none; }
@media(max-width:768px) {
  .stat-box:nth-child(2) { border-right: none; }
  .stat-box:nth-child(3) { border-top: 1px solid var(--border); }
}
.stat-box::before {
  content: ''; position: absolute;
  bottom: 0; left: 0; right: 0; height: 3px;
  background: var(--grad-brand);
  opacity: 0; transition: opacity .3s;
}
.stat-box:hover::before { opacity: 1; }
.stat-num {
  font-family: 'Clash Display', 'Bricolage Grotesque', sans-serif;
  font-size: 2rem; font-weight: 700; line-height: 1; margin-bottom: .3rem;
  background: var(--grad-brand);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
.stat-lbl {
  font-size: .75rem; color: var(--muted); font-weight: 500;
  text-transform: uppercase; letter-spacing: .5px;
}

/* ══ FEATURES ════════════════════════════════════════════════════ */
.features-section { padding: 6rem 0; }
.section-eyebrow {
  font-size: .72rem; font-weight: 700; letter-spacing: 1.5px;
  text-transform: uppercase; margin-bottom: .75rem;
  background: var(--grad-brand);
  -webkit-background-clip: text; -webkit-text-fill-color: transparent;
  background-clip: text;
}
.section-title {
  font-family: 'Clash Display', 'Bricolage Grotesque', sans-serif;
  font-size: clamp(1.6rem, 3vw, 2.25rem); font-weight: 700;
  color: var(--ink); line-height: 1.2; margin-bottom: .75rem;
  letter-spacing: -.3px;
}
.section-sub {
  font-size: .95rem; color: var(--muted); max-width: 480px; line-height: 1.72;
}
.features-grid {
  display: grid; grid-template-columns: repeat(3,1fr); gap: 1.25rem;
}
@media(max-width:860px) { .features-grid { grid-template-columns: repeat(2,1fr); } }
@media(max-width:560px) { .features-grid { grid-template-columns: 1fr; } }
.feat-card {
  background: var(--grad-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg); padding: 1.75rem 1.5rem;
  box-shadow: var(--shadow-sm); transition: all .3s;
  cursor: default; position: relative; overflow: hidden;
}
.feat-card::before {
  content: ''; position: absolute; top: 0; right: 0;
  width: 80px; height: 80px; border-radius: 50%;
  background: radial-gradient(circle, rgba(244,63,94,.08), transparent 70%);
  transform: translate(25px, -25px);
  transition: all .4s;
}
.feat-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-md); border-color: rgba(244,63,94,.2); }
.feat-card:hover::before { transform: translate(15px,-15px) scale(1.4); }
.feat-icon-wrap {
  width: 48px; height: 48px; border-radius: 12px; margin-bottom: 1.25rem;
  display: flex; align-items: center; justify-content: center; font-size: 1.2rem;
  position: relative; z-index: 1;
}
.icon-rose    { background: rgba(244,63,94,.12);  color: var(--rose); }
.icon-amber   { background: rgba(249,115,22,.12);  color: var(--amber); }
.icon-emerald { background: rgba(16,185,129,.12);  color: var(--emerald); }
.icon-violet  { background: rgba(124,58,237,.12);  color: var(--violet); }
.icon-gold    { background: rgba(234,179,8,.12);   color: var(--gold); }
.icon-fuchsia { background: rgba(217,70,239,.12);  color: var(--fuchsia); }
.feat-title {
  font-family: 'Bricolage Grotesque', 'Clash Display', sans-serif;
  font-size: .9rem; font-weight: 700; color: var(--ink);
  margin-bottom: .5rem; position: relative; z-index: 1;
}
.feat-desc {
  font-size: .84rem; color: var(--muted); line-height: 1.65;
  position: relative; z-index: 1;
}
.feat-arrow {
  display: flex; align-items: center; gap: .3rem; margin-top: 1rem;
  font-size: .75rem; font-weight: 600; color: var(--rose); opacity: 0;
  transition: opacity .2s; position: relative; z-index: 1;
}
.feat-card:hover .feat-arrow { opacity: 1; }

/* ══ HOW IT WORKS ════════════════════════════════════════════════ */
.how-section {
  padding: 5rem 0;
  background: linear-gradient(180deg, var(--amber-l) 0%, var(--surface) 100%);
  border-top: 1px solid rgba(249,115,22,.15);
  border-bottom: 1px solid rgba(249,115,22,.15);
}
.steps-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 2rem; margin-top: 3rem; }
@media(max-width:760px) { .steps-grid { grid-template-columns: 1fr; gap: 1.5rem; } }
.step-card {
  text-align: center; padding: 2rem 1.5rem;
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--radius-lg); box-shadow: var(--shadow-sm);
  transition: all .3s; position: relative;
}
.step-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }
.step-num {
  width: 42px; height: 42px; border-radius: 50%; margin: 0 auto 1.25rem;
  background: var(--grad-brand);
  color: #fff; font-family: 'Clash Display', sans-serif;
  font-size: .85rem; font-weight: 700;
  display: flex; align-items: center; justify-content: center;
  box-shadow: var(--shadow-rose);
}
.step-title { font-family: 'Bricolage Grotesque', sans-serif; font-size: .95rem; font-weight: 700; color: var(--ink); margin-bottom: .5rem; }
.step-desc  { font-size: .83rem; color: var(--muted); line-height: 1.65; }

/* ══ ROLES ═══════════════════════════════════════════════════════ */
.roles-section { padding: 5rem 0; }
.roles-grid { display: grid; grid-template-columns: repeat(3,1fr); gap: 1.25rem; margin-top: 3rem; }
@media(max-width:860px) { .roles-grid { grid-template-columns: 1fr; max-width: 460px; margin-inline: auto; } }
.role-card {
  border-radius: var(--radius-lg); padding: 2rem 1.75rem;
  border: 1px solid transparent; transition: all .3s; cursor: default;
}
.role-card.card-rose   {
  background: linear-gradient(135deg, #fff1f2 0%, #fdf2fe 100%);
  border-color: rgba(244,63,94,.15);
}
.role-card.card-amber  {
  background: linear-gradient(135deg, #fff7ed 0%, #fef9c3 100%);
  border-color: rgba(249,115,22,.15);
}
.role-card.card-violet {
  background: linear-gradient(135deg, #f5f3ff 0%, #fdf2fe 100%);
  border-color: rgba(124,58,237,.15);
}
.role-card:hover { transform: translateY(-4px); box-shadow: var(--shadow-md); }
.role-avatar {
  width: 52px; height: 52px; border-radius: 14px; margin-bottom: 1.25rem;
  display: flex; align-items: center; justify-content: center; font-size: 1.3rem;
}
.ava-rose   { background: rgba(244,63,94,.13);  color: var(--rose); }
.ava-amber  { background: rgba(249,115,22,.13); color: var(--amber); }
.ava-violet { background: rgba(124,58,237,.13); color: var(--violet); }
.role-title { font-family: 'Bricolage Grotesque', sans-serif; font-size: 1rem; font-weight: 700; color: var(--ink); margin-bottom: .5rem; }
.role-desc  { font-size: .83rem; color: var(--muted); line-height: 1.65; margin-bottom: 1.25rem; }
.role-perms { list-style: none; padding: 0; }
.role-perms li {
  font-size: .78rem; color: var(--ink-2); display: flex;
  align-items: center; gap: .4rem; padding: .2rem 0;
}
.role-perms li i { font-size: .7rem; }
.perm-rose   { color: var(--rose); }
.perm-amber  { color: var(--amber); }
.perm-violet { color: var(--violet); }

/* ══ CTA BANNER ══════════════════════════════════════════════════ */
.cta-section { padding: 5rem 0; }
.cta-box {
  background: linear-gradient(135deg, var(--rose-d) 0%, var(--amber) 45%, var(--coral) 70%, var(--violet) 100%);
  border-radius: 24px; padding: 4rem 3rem;
  text-align: center; position: relative; overflow: hidden;
  box-shadow: 0 20px 70px rgba(244,63,94,.28);
}
.cta-box::before {
  content: '';
  position: absolute; top: -40%; right: -20%;
  width: 500px; height: 500px; border-radius: 50%;
  background: radial-gradient(circle, rgba(255,255,255,.12), transparent 70%);
}
.cta-box::after {
  content: '';
  position: absolute; bottom: -40%; left: -20%;
  width: 400px; height: 400px; border-radius: 50%;
  background: radial-gradient(circle, rgba(124,58,237,.2), transparent 70%);
}
.cta-title {
  font-family: 'Clash Display', 'Bricolage Grotesque', sans-serif;
  font-size: clamp(1.5rem, 3vw, 2.1rem); font-weight: 700;
  color: #fff; margin-bottom: .75rem;
  position: relative; z-index: 1;
}
.cta-sub {
  font-size: .95rem; color: rgba(255,255,255,.7); margin-bottom: 2rem;
  max-width: 420px; margin-inline: auto;
  position: relative; z-index: 1; line-height: 1.7;
}
.cta-btns { display: flex; gap: .75rem; justify-content: center; flex-wrap: wrap; position: relative; z-index: 1; }
.btn-cta-white {
  display: inline-flex; align-items: center; gap: .5rem;
  background: #fff; color: var(--rose-d);
  padding: .75rem 1.75rem; border-radius: 12px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: .88rem; font-weight: 600;
  text-decoration: none; cursor: pointer; border: none;
  transition: all .25s; box-shadow: 0 4px 20px rgba(0,0,0,.15);
}
.btn-cta-white:hover { background: var(--rose-l); transform: translateY(-2px); color: var(--rose-d); }
.btn-cta-outline {
  display: inline-flex; align-items: center; gap: .5rem;
  background: transparent; color: rgba(255,255,255,.9);
  padding: .75rem 1.75rem; border-radius: 12px;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: .88rem; font-weight: 500;
  text-decoration: none; cursor: pointer;
  border: 1px solid rgba(255,255,255,.3);
  transition: all .25s;
}
.btn-cta-outline:hover { background: rgba(255,255,255,.12); color: #fff; border-color: rgba(255,255,255,.5); }

/* ══ FOOTER ══════════════════════════════════════════════════════ */
footer {
  background: linear-gradient(135deg, var(--ink) 0%, var(--ink-2) 100%);
  padding: 2rem 0; text-align: center;
}
.footer-brand {
  font-family: 'Clash Display', sans-serif; font-size: 1rem; font-weight: 700;
  color: #fff; margin-bottom: .5rem;
  display: flex; align-items: center; justify-content: center; gap: .4rem;
}
.footer-brand i {
  background: var(--grad-brand); -webkit-background-clip: text;
  -webkit-text-fill-color: transparent; background-clip: text;
}
.footer-copy { font-size: .78rem; color: rgba(255,255,255,.32); }
.footer-links { display: flex; gap: 1.5rem; justify-content: center; margin: .75rem 0; }
.footer-link { font-size: .78rem; color: rgba(255,255,255,.42); text-decoration: none; transition: color .2s; }
.footer-link:hover { color: rgba(255,255,255,.82); }

/* ══ MODAL ═══════════════════════════════════════════════════════ */
.modal-content {
  border: none; border-radius: 20px;
  box-shadow: 0 20px 60px rgba(244,63,94,.18); overflow: hidden;
}
.modal-header {
  padding: 1.5rem 1.75rem 1rem; border: none;
}
.modal-header-user  { background: linear-gradient(135deg, #fff7ed, #fff1f2); }
.modal-header-admin { background: linear-gradient(135deg, #f5f3ff, #fdf2fe); }
.modal-icon {
  width: 44px; height: 44px; border-radius: 12px;
  display: flex; align-items: center; justify-content: center; font-size: 1.1rem;
  margin-bottom: .75rem;
}
.icon-modal-user  { background: rgba(249,115,22,.15); color: var(--amber); }
.icon-modal-admin { background: rgba(124,58,237,.15); color: var(--violet); }
.modal-title {
  font-family: 'Bricolage Grotesque', sans-serif; font-size: 1.05rem; font-weight: 700;
  color: var(--ink); margin: 0;
}
.modal-subtitle { font-size: .8rem; color: var(--muted); margin-top: 2px; }
.modal-body { padding: 1.25rem 1.75rem; }
.modal-footer { padding: 1rem 1.75rem 1.5rem; border: none; background: var(--bg-2); }
.modal-input-label {
  font-size: .72rem; font-weight: 700; color: var(--muted);
  text-transform: uppercase; letter-spacing: .7px; margin-bottom: .35rem;
  display: block;
}
.modal-input {
  width: 100%; border: 1.5px solid var(--border); border-radius: 10px;
  padding: .65rem .9rem; font-family: 'Plus Jakarta Sans', sans-serif; font-size: .9rem;
  color: var(--ink); background: var(--surface); transition: all .2s; outline: none;
}
.modal-input:focus { border-color: var(--rose); box-shadow: 0 0 0 3px rgba(244,63,94,.1); }
.btn-modal-user {
  display: inline-flex; align-items: center; gap: .4rem;
  padding: .65rem 1.5rem; border-radius: 10px; border: none; cursor: pointer;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: .88rem; font-weight: 600;
  background: var(--grad-warm);
  color: #fff; box-shadow: var(--shadow-rose); transition: all .2s;
}
.btn-modal-user:hover { opacity: .9; transform: translateY(-1px); }
.btn-modal-admin {
  display: inline-flex; align-items: center; gap: .4rem;
  padding: .65rem 1.5rem; border-radius: 10px; border: none; cursor: pointer;
  font-family: 'Plus Jakarta Sans', sans-serif; font-size: .88rem; font-weight: 600;
  background: var(--grad-violet);
  color: #fff; box-shadow: var(--shadow-vio); transition: all .2s;
}
.btn-modal-admin:hover { opacity: .9; transform: translateY(-1px); }
.modal-pass-wrap { position: relative; }
.modal-pass-toggle {
  position: absolute; right: .75rem; top: 50%; transform: translateY(-50%);
  background: none; border: none; color: var(--light); cursor: pointer; font-size: .9rem;
}

/* ══ TOAST ═══════════════════════════════════════════════════════ */
.toast-pos { position: fixed; top: 80px; right: 1.5rem; z-index: 2000; }
.my-toast {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 14px; box-shadow: var(--shadow-md); overflow: hidden;
  min-width: 280px;
}
.toast-inner { display: flex; align-items: center; gap: .75rem; padding: 1rem 1.25rem; }
.toast-indicator { width: 4px; height: 36px; border-radius: 4px; flex-shrink: 0; }
.toast-indicator.err { background: var(--rose); }
.toast-text { font-size: .84rem; color: var(--ink); flex: 1; }
.toast-close { background: none; border: none; color: var(--light); cursor: pointer; font-size: .85rem; }

/* ══ ANIMATIONS ══════════════════════════════════════════════════ */
.reveal {
  opacity: 0; transform: translateY(24px);
  transition: opacity .6s ease, transform .6s ease;
}
.reveal.visible { opacity: 1; transform: none; }

/* ══ RESPONSIVE ══════════════════════════════════════════════════ */
@media(max-width:768px) {
  .hero { padding: 100px 0 60px; }
  .hero-sub { font-size: .9rem; }
  .hero-visual { margin-top: 2.5rem; }
  .float-badge { display: none; }
}
</style>
</head>
<body>

<!-- ══ NAVBAR ════════════════════════════════════════════════════ -->
<nav class="navbar" id="mainNav">
  <div class="container">
    <div class="d-flex align-items-center justify-content-between w-100">
      <a class="nav-brand" href="#">
        <div class="brand-icon"><i class="bi bi-boxes"></i></div>
        SIBS<span class="brand-dot">·</span>Inventory
      </a>
      <button class="hamburger" id="hamburger" aria-label="Toggle menu">
        <span></span><span></span><span></span>
      </button>
      <div class="nav-links d-flex align-items-center gap-2" id="navLinks">
        <a href="#features" class="nav-pill nav-pill-ghost">Features</a>
        <a href="#howitworks" class="nav-pill nav-pill-ghost">How it works</a>
        <% if (role == null || role.equals("customer")) { %>
        <a href="customerDashboard.jsp" class="nav-pill nav-pill-ghost">
          <i class="bi bi-shop" style="font-size:.8rem;"></i> Store
        </a>
        <% } %>
        <button class="nav-pill nav-pill-ghost" data-bs-toggle="modal" data-bs-target="#userLoginModal">
          <i class="bi bi-person" style="font-size:.8rem;"></i> Staff Login
        </button>
        <% if (!adminExists) { %>
        <a href="register.jsp" class="nav-pill nav-pill-ghost-vio">
          <i class="bi bi-shield-plus" style="font-size:.8rem;"></i> Admin Register
        </a>
        <% } else { %>
        <button class="nav-pill nav-pill-brand" data-bs-toggle="modal" data-bs-target="#adminLoginModal">
          <i class="bi bi-shield-lock" style="font-size:.8rem;"></i> Admin Login
        </button>
        <% } %>
      </div>
    </div>
  </div>
</nav>

<!-- ══ HERO ══════════════════════════════════════════════════════ -->
<section class="hero" id="home">
  <div class="container">
    <div class="row align-items-center g-5">
      <div class="col-lg-6 hero-content">
        <div class="eyebrow reveal" style="transition-delay:.05s">
          <span class="dot"></span> Version 2.0 — Now with AI Support
        </div>
        <h1 class="hero-title reveal" style="transition-delay:.12s">
          Smart Inventory<br><span class="gradient-text">& Billing System</span>
        </h1>
        <p class="hero-sub reveal" style="transition-delay:.2s">
          Streamline your entire business operation — from stock tracking and invoicing to staff management and analytics — in one beautifully simple platform.
        </p>
        <div class="hero-cta reveal" style="transition-delay:.28s">
          <a href="customerDashboard.jsp" class="btn-primary-lg">
            <i class="bi bi-shop"></i> Visit Store
          </a>
          <button class="btn-secondary-lg" data-bs-toggle="modal" data-bs-target="#userLoginModal">
            <i class="bi bi-person-check"></i> Staff Portal
          </button>
        </div>
        <div class="trust-strip reveal" style="transition-delay:.36s">
          <span class="trust-item"><i class="bi bi-check-circle-fill"></i> No setup fees</span>
          <span class="trust-sep">·</span>
          <span class="trust-item"><i class="bi bi-check-circle-fill"></i> Role-based access</span>
          <span class="trust-sep">·</span>
          <span class="trust-item"><i class="bi bi-check-circle-fill"></i> Real-time sync</span>
        </div>
      </div>
      <div class="col-lg-6 reveal" style="transition-delay:.18s">
        <div class="hero-visual">
          <!-- Floating badges -->
          <div class="float-badge badge-1">
            <i class="badge-icon bi bi-arrow-up-circle-fill" style="color:var(--emerald)"></i>
            Sales up 24% this week
          </div>
          <div class="float-badge badge-2">
            <i class="badge-icon bi bi-box-seam-fill" style="color:var(--rose)"></i>
            128 orders processed
          </div>
          <!-- Dashboard mockup -->
          <div class="dashboard-mockup">
            <div class="mockup-topbar">
              <div class="mockup-dot" style="background:#ff5f57;"></div>
              <div class="mockup-dot" style="background:#ffbe2e;margin-left:5px"></div>
              <div class="mockup-dot" style="background:#27c840;margin-left:5px"></div>
              <span class="mockup-title ms-2">SIBS Dashboard</span>
            </div>
            <div class="mockup-body">
              <div class="mockup-stat-row">
                <div class="mockup-stat">
                  <div class="mockup-stat-num">₹2.4L <span class="mockup-stat-badge badge-green">+12%</span></div>
                  <div class="mockup-stat-lbl">Revenue</div>
                </div>
                <div class="mockup-stat">
                  <div class="mockup-stat-num">584 <span class="mockup-stat-badge badge-green">+8%</span></div>
                  <div class="mockup-stat-lbl">Orders</div>
                </div>
                <div class="mockup-stat">
                  <div class="mockup-stat-num">23 <span class="mockup-stat-badge badge-red">Low</span></div>
                  <div class="mockup-stat-lbl">Low Stock</div>
                </div>
              </div>
              <div class="mockup-chart">
                <div class="mockup-chart-title">Weekly Sales</div>
                <div class="mockup-bars">
                  <div class="mockup-bar" style="height:40%;animation-delay:.1s;opacity:.5"></div>
                  <div class="mockup-bar" style="height:55%;animation-delay:.15s"></div>
                  <div class="mockup-bar" style="height:45%;animation-delay:.2s;opacity:.7"></div>
                  <div class="mockup-bar" style="height:70%;animation-delay:.25s"></div>
                  <div class="mockup-bar" style="height:60%;animation-delay:.3s;opacity:.85"></div>
                  <div class="mockup-bar" style="height:80%;animation-delay:.35s"></div>
                  <div class="mockup-bar" style="height:100%;animation-delay:.4s;background:linear-gradient(180deg,var(--rose),var(--amber))"></div>
                </div>
              </div>
              <div class="mockup-row-items">
                <div class="mockup-list-card">
                  <div class="mockup-list-title">Recent Orders</div>
                  <div class="mockup-list-item"><span>#1042 — Dairy</span><span style="color:var(--emerald);font-weight:700;">✓</span></div>
                  <div class="mockup-list-item"><span>#1043 — Fashion</span><span style="color:var(--amber);font-weight:700;">⏳</span></div>
                  <div class="mockup-list-item"><span>#1044 — Books</span><span style="color:var(--rose);font-weight:700;">→</span></div>
                </div>
                <div class="mockup-list-card">
                  <div class="mockup-list-title">Inventory</div>
                  <div class="mockup-list-item"><span>Fruits</span><span style="color:var(--emerald);">● OK</span></div>
                  <div class="mockup-list-item"><span>Dairy</span><span style="color:var(--rose);">● Low</span></div>
                  <div class="mockup-list-item"><span>Electronics</span><span style="color:var(--emerald);">● OK</span></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- ══ STATS ══════════════════════════════════════════════════════ -->
<div class="stats-section reveal">
  <div class="container">
    <div class="stats-inner">
      <div class="stat-box"><div class="stat-num">5K+</div><div class="stat-lbl">Products Managed</div></div>
      <div class="stat-box"><div class="stat-num">99.9%</div><div class="stat-lbl">Uptime</div></div>
      <div class="stat-box"><div class="stat-num">24/7</div><div class="stat-lbl">System Access</div></div>
      <div class="stat-box"><div class="stat-num">3 Roles</div><div class="stat-lbl">Access Levels</div></div>
    </div>
  </div>
</div>

<!-- ══ FEATURES ═══════════════════════════════════════════════════ -->
<section class="features-section" id="features">
  <div class="container">
    <div class="row align-items-end mb-5">
      <div class="col-lg-6">
        <div class="section-eyebrow reveal">Everything you need</div>
        <h2 class="section-title reveal" style="transition-delay:.06s">Powerful tools,<br>zero complexity</h2>
        <p class="section-sub reveal" style="transition-delay:.12s">Every feature is designed for real-world business workflows — from a single shop to a multi-branch operation.</p>
      </div>
    </div>
    <div class="features-grid">
      <div class="feat-card reveal" style="transition-delay:.05s">
        <div class="feat-icon-wrap icon-rose"><i class="bi bi-boxes"></i></div>
        <div class="feat-title">Inventory Management</div>
        <p class="feat-desc">Organise products with categories, track real-time stock levels, and get automatic low-stock alerts before you run out.</p>
        <div class="feat-arrow"><i class="bi bi-arrow-right"></i> Learn more</div>
      </div>
      <div class="feat-card reveal" style="transition-delay:.1s">
        <div class="feat-icon-wrap icon-amber"><i class="bi bi-receipt-cutoff"></i></div>
        <div class="feat-title">Billing & Invoicing</div>
        <p class="feat-desc">Generate professional GST-ready invoices in one click. Support for COD and online payment modes out of the box.</p>
        <div class="feat-arrow"><i class="bi bi-arrow-right"></i> Learn more</div>
      </div>
      <div class="feat-card reveal" style="transition-delay:.15s">
        <div class="feat-icon-wrap icon-emerald"><i class="bi bi-graph-up-arrow"></i></div>
        <div class="feat-title">Reports & Analytics</div>
        <p class="feat-desc">Visual dashboards showing revenue trends, top-selling products, and category-wise performance — updated in real time.</p>
        <div class="feat-arrow"><i class="bi bi-arrow-right"></i> Learn more</div>
      </div>
      <div class="feat-card reveal" style="transition-delay:.2s">
        <div class="feat-icon-wrap icon-violet"><i class="bi bi-people"></i></div>
        <div class="feat-title">Staff Management</div>
        <p class="feat-desc">Create staff accounts with specific roles and permissions. Monitor attendance, tasks, and notifications in one place.</p>
        <div class="feat-arrow"><i class="bi bi-arrow-right"></i> Learn more</div>
      </div>
      <div class="feat-card reveal" style="transition-delay:.25s">
        <div class="feat-icon-wrap icon-gold"><i class="bi bi-truck"></i></div>
        <div class="feat-title">Delivery Tracking</div>
        <p class="feat-desc">Assign orders to delivery agents, track dispatch status, and notify customers — from warehouse to doorstep.</p>
        <div class="feat-arrow"><i class="bi bi-arrow-right"></i> Learn more</div>
      </div>
      <div class="feat-card reveal" style="transition-delay:.3s">
        <div class="feat-icon-wrap icon-fuchsia"><i class="bi bi-robot"></i></div>
        <div class="feat-title">AI Customer Support</div>
        <p class="feat-desc">Built-in Kira AI chat widget handles order tracking, returns, and FAQs — so your team can focus on what matters.</p>
        <div class="feat-arrow"><i class="bi bi-arrow-right"></i> Learn more</div>
      </div>
    </div>
  </div>
</section>

<!-- ══ HOW IT WORKS ════════════════════════════════════════════════ -->
<section class="how-section" id="howitworks">
  <div class="container">
    <div class="text-center">
      <div class="section-eyebrow reveal">How it works</div>
      <h2 class="section-title reveal" style="transition-delay:.06s">Up and running in minutes</h2>
      <p class="section-sub mx-auto reveal" style="transition-delay:.12s">No complex configuration. No lengthy onboarding. Just set up, and you're live.</p>
    </div>
    <div class="steps-grid">
      <div class="step-card reveal" style="transition-delay:.08s">
        <div class="step-num">1</div>
        <div class="step-title">Admin Registers</div>
        <p class="step-desc">The first user creates the admin account, sets up the organisation, and configures product categories and roles.</p>
      </div>
      <div class="step-card reveal" style="transition-delay:.16s">
        <div class="step-num">2</div>
        <div class="step-title">Staff Onboarded</div>
        <p class="step-desc">Admin adds staff members with assigned roles — each person sees only what they need, keeping data secure and clean.</p>
      </div>
      <div class="step-card reveal" style="transition-delay:.24s">
        <div class="step-num">3</div>
        <div class="step-title">Go Live</div>
        <p class="step-desc">Products are listed, customers start ordering, bills are generated, and analytics update automatically in real time.</p>
      </div>
    </div>
  </div>
</section>

<!-- ══ ROLES ═══════════════════════════════════════════════════════ -->
<section class="roles-section" id="roles">
  <div class="container">
    <div class="text-center mb-2">
      <div class="section-eyebrow reveal">Role-based access</div>
      <h2 class="section-title reveal" style="transition-delay:.06s">The right tools for everyone</h2>
    </div>
    <div class="roles-grid">
      <div class="role-card card-rose reveal" style="transition-delay:.08s">
        <div class="role-avatar ava-rose"><i class="bi bi-shield-fill-check"></i></div>
        <div class="role-title">Administrator</div>
        <p class="role-desc">Full control over the entire system — manage users, view reports, configure settings, and oversee operations.</p>
        <ul class="role-perms">
          <li><i class="bi bi-check2-circle perm-rose"></i> Manage staff & permissions</li>
          <li><i class="bi bi-check2-circle perm-rose"></i> Full analytics dashboard</li>
          <li><i class="bi bi-check2-circle perm-rose"></i> System configuration</li>
          <li><i class="bi bi-check2-circle perm-rose"></i> All reports & exports</li>
        </ul>
      </div>
      <div class="role-card card-violet reveal" style="transition-delay:.14s">
        <div class="role-avatar ava-violet"><i class="bi bi-person-badge-fill"></i></div>
        <div class="role-title">Staff Member</div>
        <p class="role-desc">Handle daily operations — process orders, update inventory, manage billing, and handle delivery logistics.</p>
        <ul class="role-perms">
          <li><i class="bi bi-check2-circle perm-violet"></i> Process & track orders</li>
          <li><i class="bi bi-check2-circle perm-violet"></i> Inventory updates</li>
          <li><i class="bi bi-check2-circle perm-violet"></i> Generate invoices</li>
          <li><i class="bi bi-check2-circle perm-violet"></i> Delivery management</li>
        </ul>
      </div>
      <div class="role-card card-amber reveal" style="transition-delay:.2s">
        <div class="role-avatar ava-amber"><i class="bi bi-bag-heart-fill"></i></div>
        <div class="role-title">Customer</div>
        <p class="role-desc">Browse the store, place orders, track deliveries, manage wishlist, and interact with AI support — all from a mobile-friendly UI.</p>
        <ul class="role-perms">
          <li><i class="bi bi-check2-circle perm-amber"></i> Browse & order products</li>
          <li><i class="bi bi-check2-circle perm-amber"></i> Real-time order tracking</li>
          <li><i class="bi bi-check2-circle perm-amber"></i> AI chat support</li>
          <li><i class="bi bi-check2-circle perm-amber"></i> Wallet & wishlist</li>
        </ul>
      </div>
    </div>
  </div>
</section>

<!-- ══ CTA ════════════════════════════════════════════════════════ -->
<section class="cta-section">
  <div class="container">
    <div class="cta-box reveal">
      <h2 class="cta-title">Ready to transform your business?</h2>
      <p class="cta-sub">Join thousands of businesses already using SIBS to manage inventory, billing, and customers — seamlessly.</p>
      <div class="cta-btns">
        <a href="customerDashboard.jsp" class="btn-cta-white">
          <i class="bi bi-shop"></i> Visit the Store
        </a>
        <button class="btn-cta-outline" data-bs-toggle="modal"
                data-bs-target="<%= adminExists ? "#adminLoginModal" : "#userLoginModal" %>">
          <i class="bi bi-box-arrow-in-right"></i>
          <%= adminExists ? "Admin Login" : "Get Started" %>
        </button>
      </div>
    </div>
  </div>
</section>

<!-- ══ FOOTER ════════════════════════════════════════════════════ -->
<footer>
  <div class="container">
    <div class="footer-brand">
      <i class="bi bi-boxes"></i> SIBS · Inventory
    </div>
    <div class="footer-links">
      <a href="#features"    class="footer-link">Features</a>
      <a href="#howitworks"  class="footer-link">How it works</a>
      <a href="#roles"       class="footer-link">Roles</a>
      <a href="customerDashboard.jsp" class="footer-link">Store</a>
    </div>
    <p class="footer-copy">&copy; 2026 Smart Inventory &amp; Billing System — All rights reserved</p>
  </div>
</footer>

<!-- ══ USER LOGIN MODAL ══════════════════════════════════════════ -->
<div class="modal fade" id="userLoginModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered" style="max-width:420px;">
    <form class="modal-content" action="login" method="post">
      <div class="modal-header modal-header-user">
        <div>
          <div class="modal-icon icon-modal-user"><i class="bi bi-person-check-fill"></i></div>
          <h5 class="modal-title">Staff Login</h5>
          <p class="modal-subtitle">Access your staff or manager portal</p>
        </div>
        <button type="button" class="btn-close" data-bs-dismiss="modal" style="margin-top:-1.5rem;margin-right:-.5rem;"></button>
      </div>
      <input type="hidden" name="source" value="user">
      <div class="modal-body">
        <div class="mb-3">
          <label class="modal-input-label">Username</label>
          <input type="text" name="username" class="modal-input" placeholder="Enter your username" required autocomplete="username">
        </div>
        <div class="mb-1">
          <label class="modal-input-label">Password</label>
          <div class="modal-pass-wrap">
            <input type="password" name="password" id="userPass" class="modal-input" placeholder="Enter your password" required autocomplete="current-password">
            <button type="button" class="modal-pass-toggle" onclick="togglePass('userPass',this)">
              <i class="bi bi-eye-slash"></i>
            </button>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="submit" class="btn-modal-user">
          <i class="bi bi-box-arrow-in-right"></i> Login
        </button>
        <a href="CustomerLogin.jsp" style="font-size:.78rem;color:var(--rose);margin-left:.75rem;text-decoration:none;font-weight:500;">
          <i class="bi bi-bag-heart"></i> Customer login →
        </a>
      </div>
    </form>
  </div>
</div>

<!-- ══ ADMIN LOGIN MODAL ═════════════════════════════════════════ -->
<div class="modal fade" id="adminLoginModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered" style="max-width:420px;">
    <form class="modal-content" action="login" method="post">
      <div class="modal-header modal-header-admin">
        <div>
          <div class="modal-icon icon-modal-admin"><i class="bi bi-shield-lock-fill"></i></div>
          <h5 class="modal-title">Administrator Login</h5>
          <p class="modal-subtitle">Secure access to the admin panel</p>
        </div>
        <button type="button" class="btn-close" data-bs-dismiss="modal" style="margin-top:-1.5rem;margin-right:-.5rem;"></button>
      </div>
      <div class="modal-body">
        <div class="mb-3">
          <label class="modal-input-label">Admin Username</label>
          <input type="text" name="username" class="modal-input" placeholder="Enter admin username" required autocomplete="username">
        </div>
        <div class="mb-1">
          <label class="modal-input-label">Password</label>
          <div class="modal-pass-wrap">
            <input type="password" name="password" id="adminPass" class="modal-input" placeholder="Enter admin password" required autocomplete="current-password">
            <button type="button" class="modal-pass-toggle" onclick="togglePass('adminPass',this)">
              <i class="bi bi-eye-slash"></i>
            </button>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="submit" class="btn-modal-admin">
          <i class="bi bi-shield-check"></i> Secure Login
        </button>
      </div>
    </form>
  </div>
</div>

<!-- ══ TOAST ══════════════════════════════════════════════════════ -->
<div class="toast-pos" id="toastContainer">
  <% if (!error.isEmpty()) { %>
  <div class="my-toast" id="errorToast">
    <div class="toast-inner">
      <div class="toast-indicator err"></div>
      <div class="toast-text"><i class="bi bi-exclamation-triangle-fill me-1" style="color:var(--rose);"></i> <%= error %></div>
      <button class="toast-close" onclick="document.getElementById('errorToast').remove()">
        <i class="bi bi-x"></i>
      </button>
    </div>
  </div>
  <% } %>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
/* Navbar scroll shadow */
const nav = document.getElementById('mainNav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 20);
});

/* Hamburger toggle */
const ham = document.getElementById('hamburger');
const navLinks = document.getElementById('navLinks');
ham.addEventListener('click', () => {
  navLinks.classList.toggle('open');
  ham.closest('nav').classList.toggle('nav-mobile-open');
});
/* Close mobile menu on link click */
navLinks.querySelectorAll('a, button[data-bs-toggle]').forEach(el => {
  el.addEventListener('click', () => {
    navLinks.classList.remove('open');
    ham.closest('nav').classList.remove('nav-mobile-open');
  });
});

/* Password toggle */
function togglePass(id, btn) {
  const inp = document.getElementById(id);
  const showing = inp.type === 'text';
  inp.type = showing ? 'password' : 'text';
  btn.querySelector('i').className = showing ? 'bi bi-eye-slash' : 'bi bi-eye';
}

/* Scroll reveal */
const revealEls = document.querySelectorAll('.reveal');
const observer = new IntersectionObserver((entries) => {
  entries.forEach((e) => {
    if (e.isIntersecting) {
      e.target.classList.add('visible');
      observer.unobserve(e.target);
    }
  });
}, { threshold: 0.12 });
revealEls.forEach(el => observer.observe(el));

/* Auto-open login modal if there's an error */
<% if (!error.isEmpty()) { %>
document.addEventListener('DOMContentLoaded', () => {
  new bootstrap.Modal(document.getElementById('userLoginModal')).show();
  setTimeout(() => {
    const t = document.getElementById('errorToast');
    if (t) t.style.opacity = '0';
    setTimeout(() => t && t.remove(), 400);
  }, 4000);
});
<% } %>

/* Smooth scroll for anchor links */
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    const target = document.querySelector(a.getAttribute('href'));
    if (target) { e.preventDefault(); target.scrollIntoView({ behavior: 'smooth' }); }
  });
});
</script>
</body>
</html>
