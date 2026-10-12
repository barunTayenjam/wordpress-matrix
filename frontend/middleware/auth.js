// Dashboard token auth (FEATURES-PLAN.md Phase 8).
// Policy (pinned by __tests__/auth.test.js):
//   - no MATRIX_DASHBOARD_TOKEN → open behavior + warning banner header
//     (server binds loopback-only; app.js handles the bind)
//   - token set → /health exempt, static + dashboard shell exempt (non-/api),
//     every other /api/* path requires Authorization: Bearer <token>
//     compared with crypto.timingSafeEqual.

const crypto = require('crypto');

function tokenEquals(provided, expected) {
  const a = Buffer.from(String(provided));
  const b = Buffer.from(String(expected));
  // different lengths can't be equal; still burn a compare to avoid a
  // cheap length-based timing oracle
  if (a.length !== b.length) {
    crypto.timingSafeEqual(a, a);
    return false;
  }
  return crypto.timingSafeEqual(a, b);
}

function extractToken(req) {
  const header = req.get('authorization') || '';
  if (header.startsWith('Bearer ')) return header.slice(7);
  return req.get('x-matrix-token') || '';
}

function createAuthMiddleware({ token } = {}) {
  return function authMiddleware(req, res, next) {
    if (!token) {
      // open mode: advertise the exposure, never block
      res.setHeader('X-Matrix-Auth-Warning', 'no-dashboard-token; bound to loopback');
      return next();
    }
    if (req.path === '/health') return next();
    if (!req.path.startsWith('/api/')) return next(); // static assets + dashboard shell
    if (tokenEquals(extractToken(req), token)) return next();
    return res
      .status(401)
      .json({ success: false, error: { code: 'UNAUTHORIZED', message: 'Missing or invalid dashboard token' } });
  };
}

module.exports = { createAuthMiddleware, tokenEquals };
