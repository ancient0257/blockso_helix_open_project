/* ── Helix Website — main.js v2 ── */

'use strict';

// ── Canvas particle network ─────────────────────────────────
(function initCanvas() {
  const canvas = document.getElementById('hero-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');

  const PURPLE = 'rgba(139,92,246,';
  const CYAN   = 'rgba(34,211,238,';

  let W, H, nodes, raf;

  function resize() {
    W = canvas.width  = window.innerWidth;
    H = canvas.height = window.innerHeight;
    buildNodes();
  }

  function buildNodes() {
    const count = Math.min(Math.floor((W * H) / 18000), 55);
    nodes = Array.from({ length: count }, () => ({
      x:  Math.random() * W,
      y:  Math.random() * H,
      vx: (Math.random() - 0.5) * 0.3,
      vy: (Math.random() - 0.5) * 0.3,
      r:  Math.random() * 1.5 + 0.8,
      hue: Math.random() > 0.5 ? PURPLE : CYAN,
    }));
  }

  function draw() {
    ctx.clearRect(0, 0, W, H);

    // Move
    nodes.forEach(n => {
      n.x += n.vx;
      n.y += n.vy;
      if (n.x < 0 || n.x > W) n.vx *= -1;
      if (n.y < 0 || n.y > H) n.vy *= -1;
    });

    // Edges
    const LINK_DIST = 160;
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const dx = nodes[i].x - nodes[j].x;
        const dy = nodes[i].y - nodes[j].y;
        const d2 = dx * dx + dy * dy;
        if (d2 < LINK_DIST * LINK_DIST) {
          const alpha = (1 - Math.sqrt(d2) / LINK_DIST) * 0.25;
          ctx.beginPath();
          ctx.strokeStyle = `${nodes[i].hue}${alpha})`;
          ctx.lineWidth = 0.6;
          ctx.moveTo(nodes[i].x, nodes[i].y);
          ctx.lineTo(nodes[j].x, nodes[j].y);
          ctx.stroke();
        }
      }
    }

    // Nodes
    nodes.forEach(n => {
      ctx.beginPath();
      ctx.arc(n.x, n.y, n.r, 0, Math.PI * 2);
      ctx.fillStyle = `${n.hue}0.6)`;
      ctx.fill();
    });

    raf = requestAnimationFrame(draw);
  }

  // Only run if prefers-reduced-motion is not set
  const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!prefersReduced) {
    window.addEventListener('resize', resize, { passive: true });
    resize();
    draw();
  }
})();

// ── Navbar scroll ───────────────────────────────────────────
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 24);
}, { passive: true });

// ── Intersection observer for scroll animations ─────────────
const scrollObs = new IntersectionObserver(
  entries => entries.forEach(e => {
    if (e.isIntersecting) e.target.classList.add('visible');
  }),
  { threshold: 0.1, rootMargin: '0px 0px -48px 0px' }
);
document.querySelectorAll('.animate-on-scroll').forEach(el => scrollObs.observe(el));

// ── Counter animation ───────────────────────────────────────
function countUp(el, target, ms = 1000) {
  const start = performance.now();
  const update = t => {
    const p = Math.min((t - start) / ms, 1);
    el.textContent = Math.round((1 - Math.pow(1 - p, 3)) * target);
    if (p < 1) requestAnimationFrame(update);
    else el.textContent = target;
  };
  requestAnimationFrame(update);
}
const statObs = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      const t = parseInt(e.target.dataset.target, 10);
      countUp(e.target, t);
      statObs.unobserve(e.target);
    }
  });
}, { threshold: 0.6 });
document.querySelectorAll('[data-target]').forEach(el => statObs.observe(el));

// ── Smooth anchor scroll ────────────────────────────────────
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    const target = document.querySelector(a.getAttribute('href'));
    if (!target) return;
    e.preventDefault();
    const top = target.getBoundingClientRect().top + window.scrollY - navbar.offsetHeight - 20;
    window.scrollTo({ top, behavior: 'smooth' });
  });
});

// ── Active nav highlight ────────────────────────────────────
const navLinks = document.querySelectorAll('.nav-link');
const sectionObs = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      navLinks.forEach(l => l.classList.toggle('active', l.getAttribute('href') === `#${e.target.id}`));
    }
  });
}, { rootMargin: '-38% 0px -56% 0px' });
document.querySelectorAll('section[id]').forEach(s => sectionObs.observe(s));

// ── Card micro-tilt ─────────────────────────────────────────
const TILT_MAX = 5;
document.querySelectorAll(
  '.dashboard-card, .problem-card, .source-card, .contrib-card'
).forEach(card => {
  card.addEventListener('mousemove', e => {
    const r  = card.getBoundingClientRect();
    const x  = (e.clientX - r.left) / r.width  - 0.5;
    const y  = (e.clientY - r.top)  / r.height - 0.5;
    card.style.transition = 'none';
    card.style.transform  = `translateY(-4px) rotateX(${-y * TILT_MAX}deg) rotateY(${x * TILT_MAX}deg)`;
  });
  card.addEventListener('mouseleave', () => {
    card.style.transition = 'transform 0.4s var(--ease, ease)';
    card.style.transform  = '';
  });
});

// ── Terminal — click to copy kurtosis command ───────────────
const terminal = document.getElementById('hero-terminal');
const termTitle = document.getElementById('terminal-title');
if (terminal && termTitle) {
  terminal.addEventListener('click', async () => {
    const cmd = 'kurtosis run github.com/ethpandaops/ethereum-package --enclave my-devnet';
    try {
      await navigator.clipboard.writeText(cmd);
      const orig = termTitle.textContent;
      termTitle.textContent = '✓ copied to clipboard!';
      termTitle.style.color = '#4ade80';
      setTimeout(() => { termTitle.textContent = orig; termTitle.style.color = ''; }, 2200);
    } catch (_) { /* clipboard not available */ }
  });
  terminal.style.cursor = 'pointer';
}
