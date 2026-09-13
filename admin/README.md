# admin/

A copy of the current admin dashboard as it exists in `backend/apps/dashboard`
(views, forms, urls) and its templates/static assets, split into two folders
for reference:

- `backend/apps/dashboard/` - Django views, forms, URLs, and business logic
  for the admin panel (order management, settings, push/Telegram, etc.)
- `frontend/templates/` and `frontend/static/` - the server-rendered HTML
  templates and CSS/JS/assets the dashboard views render.

## Important: this does not run on Vercel as-is

This is a **server-rendered Django app** - it depends on Django sessions,
`login_required`, the ORM (models living in `backend/apps/merchant`,
`backend/apps/customer`, `backend/apps/product`), and Django's template
engine. Vercel does not host stateful Django apps this way; it expects
static sites or serverless functions (e.g. Next.js/React).

This folder is a snapshot for reference or as a starting point for a
rewrite - it is **not** a working, independently deployable app. Turning
this into something Vercel can serve would require rebuilding the frontend
as a separate SPA (e.g. Next.js/React) that calls the Django backend's
REST API, since Vercel can't run the Python/Django process itself.

The actual live admin panel continues to run as part of `backend/`
(Django, deployed on Render) until/unless that rewrite happens.
