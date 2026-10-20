#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define FV_MAX_SITES 8
#define FV_MAX_ARCS (1 + 2 * (FV_MAX_SITES - 1))
#define FV_MAX_VERTICES 32
#define FV_MAX_OUTPUT_I64 1024
#define FV_EPS 1e-10

typedef struct { double x, y; } FvPoint;
typedef struct { int site, prev, next, active; } FvArc;
typedef struct { double y, x; int arc, left, right; } FvCircle;
typedef struct { int64_t n, d; } FvRat;
typedef struct { FvRat x, y; } FvRPoint;

static int64_t fv_abs(int64_t x) { return x < 0 ? -x : x; }
static int64_t fv_gcd(int64_t a, int64_t b) {
    a = fv_abs(a); b = fv_abs(b);
    while (b) { int64_t t = a % b; a = b; b = t; }
    return a ? a : 1;
}
static FvRat fv_rat(int64_t n, int64_t d) {
    if (d < 0) { n = -n; d = -d; }
    int64_t g = fv_gcd(n, d);
    FvRat r = { n / g, d / g };
    return r;
}
static FvRat fv_add(FvRat a, FvRat b) { return fv_rat(a.n * b.d + b.n * a.d, a.d * b.d); }
static FvRat fv_sub(FvRat a, FvRat b) { return fv_rat(a.n * b.d - b.n * a.d, a.d * b.d); }
static FvRat fv_mul(FvRat a, FvRat b) { return fv_rat(a.n * b.n, a.d * b.d); }
static FvRat fv_div(FvRat a, FvRat b) { return fv_rat(a.n * b.d, a.d * b.n); }
static int fv_cmp(FvRat a, FvRat b) {
    int64_t left = a.n * b.d, right = b.n * a.d;
    return (left > right) - (left < right);
}
static int fv_point_eq(FvRPoint a, FvRPoint b) { return fv_cmp(a.x, b.x) == 0 && fv_cmp(a.y, b.y) == 0; }
static int fv_point_less(FvRPoint a, FvRPoint b) {
    int x = fv_cmp(a.x, b.x);
    return x < 0 || (x == 0 && fv_cmp(a.y, b.y) < 0);
}
static int fv_cross_i(FvPoint a, FvPoint b, FvPoint c) {
    int64_t cross = ((int64_t)b.x - (int64_t)a.x) * ((int64_t)c.y - (int64_t)a.y) -
                    ((int64_t)b.y - (int64_t)a.y) * ((int64_t)c.x - (int64_t)a.x);
    return (cross > 0) - (cross < 0);
}
static double fv_breakpoint(FvPoint p, FvPoint q, double line_y) {
    if (fabs(p.y - q.y) < FV_EPS) return (p.x + q.x) * 0.5;
    double dp = p.y - line_y, dq = q.y - line_y;
    double a = q.y - p.y;
    double b = -2.0 * p.x * dq + 2.0 * q.x * dp;
    double c = (p.x * p.x + p.y * p.y - line_y * line_y) * dq -
               (q.x * q.x + q.y * q.y - line_y * line_y) * dp;
    double disc = b * b - 4.0 * a * c;
    if (disc < 0.0 && disc > -FV_EPS) disc = 0.0;
    double root = sqrt(disc);
    double r1 = (-b - root) / (2.0 * a), r2 = (-b + root) / (2.0 * a);
    return p.y < q.y ? (r1 > r2 ? r1 : r2) : (r1 < r2 ? r1 : r2);
}
static int fv_circle(FvPoint a, FvPoint b, FvPoint c, double sweep_y, FvCircle *out, int arc, int left, int right) {
    if (fv_cross_i(a, b, c) >= 0) return 0;
    double aa = a.x * a.x + a.y * a.y, bb = b.x * b.x + b.y * b.y, cc = c.x * c.x + c.y * c.y;
    double d = 2.0 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
    if (fabs(d) < FV_EPS) return 0;
    double x = (aa * (b.y - c.y) + bb * (c.y - a.y) + cc * (a.y - b.y)) / d;
    double y = (aa * (c.x - b.x) + bb * (a.x - c.x) + cc * (b.x - a.x)) / d;
    double dx = x - a.x, dy = y - a.y;
    double bottom = y - sqrt(dx * dx + dy * dy);
    if (!(bottom < sweep_y - FV_EPS)) return 0;
    out->y = bottom; out->x = x; out->arc = arc; out->left = left; out->right = right;
    return 1;
}
static int fv_add_arc(FvArc arcs[FV_MAX_ARCS], int *count, int site, int prev, int next) {
    if (*count >= FV_MAX_ARCS) return -1;
    int id = (*count)++;
    arcs[id] = (FvArc){ site, prev, next, 1 };
    return id;
}
static void fv_put_i64(uint8_t *out, size_t slot, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[slot * 8 + i] = (uint8_t)(bits >> (8 * i));
}
static FvRat fv_dist(FvRPoint p, int64_t a, int64_t b, int64_t c) {
    FvRat x = fv_mul(fv_rat(a, 1), p.x), y = fv_mul(fv_rat(b, 1), p.y);
    return fv_sub(fv_add(x, y), fv_rat(c, 1));
}
static FvRPoint fv_intersection(FvRPoint p, FvRPoint q, FvRat dp, FvRat dq) {
    FvRat t = fv_div(dp, fv_sub(dp, dq));
    FvRPoint r = { fv_add(p.x, fv_mul(t, fv_sub(q.x, p.x))),
                   fv_add(p.y, fv_mul(t, fv_sub(q.y, p.y))) };
    return r;
}
static void fv_push(FvRPoint *poly, int *count, FvRPoint p) {
    if (*count == 0 || !fv_point_eq(poly[*count - 1], p)) poly[(*count)++] = p;
}
static int fv_clip(FvRPoint *poly, int count, int64_t a, int64_t b, int64_t c) {
    FvRPoint next[FV_MAX_VERTICES]; int n = 0;
    for (int i = 0; i < count; ++i) {
        FvRPoint p = poly[i], q = poly[(i + 1) % count];
        FvRat dp = fv_dist(p, a, b, c), dq = fv_dist(q, a, b, c);
        int pin = dp.n <= 0, qin = dq.n <= 0;
        if (pin && qin) fv_push(next, &n, q);
        else if (pin && !qin) fv_push(next, &n, fv_intersection(p, q, dp, dq));
        else if (!pin && qin) { fv_push(next, &n, fv_intersection(p, q, dp, dq)); fv_push(next, &n, q); }
    }
    if (n > 1 && fv_point_eq(next[0], next[n - 1])) --n;
    for (int i = 0; i < n; ++i) poly[i] = next[i];
    return n;
}
static int fv_general_position(const int64_t *in, int n) {
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) {
        int64_t xi = in[1 + 2 * i], yi = in[2 + 2 * i], xj = in[1 + 2 * j], yj = in[2 + 2 * j];
        if (xi == xj && yi == yj) return 0;
        if (yi == yj) return 0;
    }
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) for (int k = j + 1; k < n; ++k) {
        int64_t ax = in[1 + 2 * i], ay = in[2 + 2 * i], bx = in[1 + 2 * j], by = in[2 + 2 * j], cx = in[1 + 2 * k], cy = in[2 + 2 * k];
        if ((bx - ax) * (cy - ay) == (by - ay) * (cx - ax)) return 0;
    }
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) for (int k = j + 1; k < n; ++k) for (int l = k + 1; l < n; ++l) {
        int64_t ax = in[1 + 2 * i] - in[1 + 2 * l], ay = in[2 + 2 * i] - in[2 + 2 * l];
        int64_t bx = in[1 + 2 * j] - in[1 + 2 * l], by = in[2 + 2 * j] - in[2 + 2 * l];
        int64_t cx = in[1 + 2 * k] - in[1 + 2 * l], cy = in[2 + 2 * k] - in[2 + 2 * l];
        int64_t aa = ax * ax + ay * ay, bb = bx * bx + by * by, cc = cx * cx + cy * cy;
        int64_t det = ax * (by * cc - bb * cy) - ay * (bx * cc - bb * cx) + aa * (bx * cy - by * cx);
        if (det == 0) return 0;
    }
    return 1;
}

int64_t fortune_voronoi(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 3 || input[0] < 1 || input[0] > FV_MAX_SITES || length != 1 + 2 * (size_t)input[0]) return -1;
    int n = (int)input[0];
    for (int i = 0; i < n; ++i) if (input[1 + 2 * i] < -8 || input[1 + 2 * i] > 8 || input[2 + 2 * i] < -8 || input[2 + 2 * i] > 8) return -1;
    if (!fv_general_position(input, n)) return -1;
    FvPoint sites[FV_MAX_SITES]; int order[FV_MAX_SITES];
    for (int i = 0; i < n; ++i) { sites[i] = (FvPoint){(double)input[1 + 2 * i], (double)input[2 + 2 * i]}; order[i] = i; }
    for (int i = 1; i < n; ++i) { int v = order[i], j = i; while (j > 0 && sites[order[j - 1]].y < sites[v].y) { order[j] = order[j - 1]; --j; } order[j] = v; }
    FvArc arcs[FV_MAX_ARCS] = {{0}}; int arc_count = 1, first = 0;
    arcs[0] = (FvArc){order[0], -1, -1, 1};
    int next_site = 1; double sweep = sites[order[0]].y;
    uint8_t adjacent[FV_MAX_SITES][FV_MAX_SITES] = {{0}};
    while (next_site < n || first >= 0) {
        FvCircle best = {0}; int has_circle = 0;
        for (int b = first; b >= 0; b = arcs[b].next) {
            int l = arcs[b].prev, r = arcs[b].next;
            if (l < 0 || r < 0) continue;
            int si = arcs[l].site, sj = arcs[b].site, sk = arcs[r].site;
            if (si == sj || sj == sk || si == sk) continue;
            FvCircle candidate;
            if (fv_circle(sites[si], sites[sj], sites[sk], sweep, &candidate, b, l, r) &&
                (!has_circle || candidate.y > best.y + FV_EPS || (fabs(candidate.y - best.y) <= FV_EPS && b < best.arc))) {
                best = candidate; has_circle = 1;
            }
        }
        int process_site = next_site < n && (!has_circle || sites[order[next_site]].y > best.y + FV_EPS);
        if (!process_site && !has_circle) break;
        if (process_site) {
            int site = order[next_site++]; sweep = sites[site].y;
            int arc = first;
            while (arcs[arc].next >= 0) {
                int right = arcs[arc].next;
                if (sites[site].x < fv_breakpoint(sites[arcs[arc].site], sites[arcs[right].site], sweep)) break;
                arc = right;
            }
            int old_next = arcs[arc].next, old_site = arcs[arc].site;
            int middle = fv_add_arc(arcs, &arc_count, site, arc, -1);
            int right = fv_add_arc(arcs, &arc_count, old_site, middle, old_next);
            if (middle < 0 || right < 0) return -1;
            arcs[arc].next = middle; arcs[middle].next = right; arcs[right].prev = middle;
            if (old_next >= 0) arcs[old_next].prev = right;
            adjacent[old_site][site] = adjacent[site][old_site] = 1;
        } else {
            int arc = best.arc, left = best.left, right = best.right;
            if (!arcs[arc].active || arcs[arc].prev != left || arcs[arc].next != right) return -1;
            sweep = best.y;
            int ls = arcs[left].site, rs = arcs[right].site;
            adjacent[ls][rs] = adjacent[rs][ls] = 1;
            arcs[left].next = right; arcs[right].prev = left; arcs[arc].active = 0;
            if (first == arc) first = right;
        }
    }

    int64_t values[FV_MAX_OUTPUT_I64]; size_t used = 0;
    values[used++] = n;
    for (int i = 0; i < n; ++i) {
        FvRPoint poly[FV_MAX_VERTICES] = {
            {{-16,1},{-16,1}}, {{16,1},{-16,1}}, {{16,1},{16,1}}, {{-16,1},{16,1}}
        };
        int count = 4;
        for (int j = 0; j < n; ++j) if (adjacent[i][j]) {
            int64_t x = input[1 + 2 * j], y = input[2 + 2 * j];
            int64_t sx = input[1 + 2 * i], sy = input[2 + 2 * i];
            count = fv_clip(poly, count, 2 * (x - sx), 2 * (y - sy), x * x + y * y - sx * sx - sy * sy);
        }
        if (count < 3 || used + 2 + 4 * (size_t)count > FV_MAX_OUTPUT_I64) return -1;
        int start = 0;
        for (int j = 1; j < count; ++j) if (fv_point_less(poly[j], poly[start])) start = j;
        values[used++] = i; values[used++] = count;
        for (int j = 0; j < count; ++j) {
            FvRPoint p = poly[(start + j) % count];
            values[used++] = p.x.n; values[used++] = p.x.d; values[used++] = p.y.n; values[used++] = p.y.d;
        }
    }
    size_t bytes = used * 8;
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < used; ++i) fv_put_i64(output, i, values[i]);
    return (int64_t)bytes;
}
