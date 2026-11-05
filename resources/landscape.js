// The canvas itself rotates when OS/browser orientation locking is unavailable.
// Godot owns rendering, but resizePolicy=0 delegates its physical surface to us.
(() => {
  let rotated = false;
  const getCanvas = () => document.getElementById('canvas');
  function apply() {
    const canvas = getCanvas();
    if (!canvas) return;
    rotated = window.innerHeight > window.innerWidth;
    const width = rotated ? window.innerHeight : window.innerWidth;
    const height = rotated ? window.innerWidth : window.innerHeight;
    const ratio = window.devicePixelRatio || 1;
    if (canvas.width !== Math.round(width * ratio)) canvas.width = Math.round(width * ratio);
    if (canvas.height !== Math.round(height * ratio)) canvas.height = Math.round(height * ratio);
    Object.assign(canvas.style, {
      position: 'fixed', left: '50%', top: '50%', margin: '0', padding: '0', border: '0',
      width: width + 'px', height: height + 'px', display: 'block', touchAction: 'none',
      transformOrigin: '50% 50%',
      transform: 'translate(-50%, -50%)' + (rotated ? ' rotate(90deg)' : '')
    });
    canvas.dataset.landscapeRotation = rotated ? '90' : '0';
    document.documentElement.style.overflow = 'hidden';
    document.body.style.margin = '0';
    document.body.style.overflow = 'hidden';
    document.body.style.overscrollBehavior = 'none';
  }
  window.deadlightLandscape = {
    apply,
    position(event, canvas, rect) {
      if (rotated) return [
        (event.clientY - rect.top) * canvas.width / rect.height,
        (rect.right - event.clientX) * canvas.height / rect.width
      ];
      return [(event.clientX - rect.left) * canvas.width / rect.width,
              (event.clientY - rect.top) * canvas.height / rect.height];
    },
    relative(event, canvas, rect) {
      if (rotated) return [event.movementY * canvas.width / rect.height,
                           -event.movementX * canvas.height / rect.width];
      return [event.movementX * canvas.width / rect.width,
              event.movementY * canvas.height / rect.height];
    }
  };
  window.addEventListener('resize', apply);
  window.addEventListener('orientationchange', () => requestAnimationFrame(apply));
  if (window.visualViewport) window.visualViewport.addEventListener('resize', apply);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', apply);
  else apply();
})();
