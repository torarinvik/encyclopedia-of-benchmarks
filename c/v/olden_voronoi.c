#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 5
#define MAX_EDGES 32
#define SCALE 1000.0

typedef struct { double x, y, norm; } Point;
typedef struct { int left, right; } EdgePair;

static Point points[MAX_POINTS];
static int left_child[MAX_POINTS], right_child[MAX_POINTS];
static int onext[MAX_EDGES * 4], origin[MAX_EDGES * 4], alive[MAX_EDGES];
static int edge_count;

static int sym(int e) { return e ^ 2; }
static int rot(int e) { return (e & ~3) | ((e + 1) & 3); }
static int rotinv(int e) { return (e & ~3) | ((e + 3) & 3); }
static int lnext(int e) { return rot(onext[rotinv(e)]); }
static int oprev(int e) { return rot(onext[rot(e)]); }
static int rprev(int e) { return onext[sym(e)]; }
static int lprev(int e) { return sym(onext[e]); }
static int orig(int e) { return origin[e]; }
static int dest(int e) { return origin[sym(e)]; }

static int ccw(int a, int b, int c) {
    double determinant = (points[a].x - points[c].x) * (points[b].y - points[c].y)
                       - (points[b].x - points[c].x) * (points[a].y - points[c].y);
    return determinant > 0.0;
}

static int incircle(int a, int b, int c, int d) {
    double adx = points[a].x - points[d].x, ady = points[a].y - points[d].y;
    double bdx = points[b].x - points[d].x, bdy = points[b].y - points[d].y;
    double cdx = points[c].x - points[d].x, cdy = points[c].y - points[d].y;
    double result = (points[a].norm - points[d].norm) * (bdx * cdy - bdy * cdx);
    result += (points[b].norm - points[d].norm) * (cdx * ady - cdy * adx);
    result += (points[c].norm - points[d].norm) * (adx * bdy - ady * bdx);
    return 0.0 < result;
}

static int make_edge(int a, int b) {
    int e = edge_count++ * 4;
    alive[e / 4] = 1;
    onext[e] = e; origin[e] = a;
    onext[e + 1] = e + 3;
    onext[e + 2] = e + 2; origin[e + 2] = b;
    onext[e + 3] = e + 1;
    return e;
}

static void splice(int a, int b) {
    int alpha = rot(onext[a]), beta = rot(onext[b]);
    int t1 = onext[beta], temp = onext[alpha];
    onext[alpha] = t1; onext[beta] = temp;
    temp = onext[a]; t1 = onext[b];
    onext[b] = temp; onext[a] = t1;
}

static int connect_left(int a, int b) {
    int ans = make_edge(dest(a), orig(b));
    splice(ans, lnext(a));
    splice(sym(ans), b);
    return ans;
}

static int connect_right(int a, int b) {
    int ans = make_edge(dest(a), orig(b));
    splice(ans, sym(a));
    splice(sym(ans), oprev(b));
    return ans;
}

static void delete_edge(int e) {
    int f = oprev(e);
    splice(e, f);
    f = oprev(sym(e));
    splice(sym(e), f);
    alive[e / 4] = 0;
}

static void swap_edge(int e) {
    int a = oprev(e), syme = sym(e), b = oprev(syme);
    splice(e, a); splice(syme, b);
    splice(e, lnext(a)); splice(syme, lnext(b));
    int a1 = dest(a), b1 = dest(b);
    origin[e] = a1;
    origin[sym(e)] = b1;
}

static int valid(int l, int base) { return ccw(orig(base), dest(l), dest(base)); }

static EdgePair do_merge(int ldo, int ldi, int rdi, int rdo) {
    int basel, lcand, rcand, t;
    while (1) {
        int t3 = orig(rdi), t1 = orig(ldi), t2 = dest(ldi);
        while (ccw(t1, t2, t3)) {
            ldi = lnext(ldi); t1 = orig(ldi); t2 = dest(ldi);
        }
        t2 = dest(rdi);
        if (ccw(t2, t3, t1)) rdi = rprev(rdi);
        else break;
    }
    basel = connect_left(sym(rdi), ldi);
    lcand = rprev(basel); rcand = oprev(basel);
    t1 = orig(basel); t2 = dest(basel);
    if (t1 == orig(rdo)) rdo = basel;
    if (t2 == orig(ldo)) ldo = sym(basel);
    while (1) {
        int v1, v2, v3, v4;
        t = onext[lcand];
        if (valid(t, basel)) {
            v4 = orig(basel); v1 = dest(lcand); v3 = orig(lcand); v2 = dest(t);
            while (incircle(v1, v2, v3, v4)) {
                delete_edge(lcand); lcand = t; t = onext[lcand];
                v1 = dest(lcand); v3 = orig(lcand); v2 = dest(t);
            }
        }
        t = oprev(rcand);
        if (valid(t, basel)) {
            v4 = dest(basel); v1 = dest(t); v2 = dest(rcand); v3 = orig(rcand);
            while (incircle(v1, v2, v3, v4)) {
                delete_edge(rcand); rcand = t; t = oprev(rcand);
                v2 = dest(rcand); v3 = orig(rcand); v1 = dest(t);
            }
        }
        int lvalid = valid(lcand, basel), rvalid = valid(rcand, basel);
        if (!lvalid && !rvalid) return (EdgePair){ldo, rdo};
        v1 = dest(lcand); v2 = orig(lcand); v3 = orig(rcand); v4 = dest(rcand);
        if (!lvalid || (rvalid && incircle(v1, v2, v3, v4))) {
            basel = connect_left(rcand, sym(basel));
            rcand = lnext(sym(basel));
        } else {
            basel = sym(connect_right(lcand, basel));
            lcand = rprev(basel);
        }
    }
}

static int get_low(int node) {
    while (left_child[node] >= 0) node = left_child[node];
    return node;
}

static EdgePair build_delaunay(int tree, int extra) {
    if (tree >= 0 && right_child[tree] >= 0) {
        int minx = get_low(tree), maxx = extra;
        EdgePair delright = build_delaunay(right_child[tree], extra);
        EdgePair delleft = build_delaunay(left_child[tree], tree);
        EdgePair result = do_merge(delleft.left, delleft.right, delright.left, delright.right);
        while (orig(result.left) != minx) result.left = rprev(result.left);
        while (orig(result.right) != maxx) result.right = lprev(result.right);
        return result;
    }
    if (tree < 0) return (EdgePair){-1, -1};
    if (left_child[tree] < 0) {
        int a = make_edge(tree, extra);
        return (EdgePair){a, sym(a)};
    }
    int s1 = left_child[tree], s2 = tree, s3 = extra;
    int a = make_edge(s1, s2), b = make_edge(s2, s3);
    splice(sym(a), b);
    int c = connect_left(b, a);
    if (ccw(s1, s3, s2)) return (EdgePair){sym(c), c};
    EdgePair result = {a, sym(b)};
    if (!ccw(s1, s2, s3)) delete_edge(c);
    return result;
}

static double circle_center_x(int a, int b, int c) {
    double vx = points[b].x - points[a].x, vy = points[b].y - points[a].y;
    double wx = points[c].x - points[a].x, wy = points[c].y - points[a].y;
    double d3 = vx * wy - vy * wx, d2 = -2.0 * d3;
    double d4 = (points[c].x - points[b].x) * wx + (points[c].y - points[b].y) * wy;
    return 0.5 * (points[a].x + points[b].x) + (d4 / d2) * vy;
}

static double circle_center_y(int a, int b, int c) {
    double vx = points[b].x - points[a].x, vy = points[b].y - points[a].y;
    double wx = points[c].x - points[a].x, wy = points[c].y - points[a].y;
    double d3 = vx * wy - vy * wx, d2 = -2.0 * d3;
    double d4 = (points[c].x - points[b].x) * wx + (points[c].y - points[b].y) * wy;
    return 0.5 * (points[a].y + points[b].y) - (d4 / d2) * vx;
}

static int face_center(int e, double *cx, double *cy) {
    int e2 = lnext(e), e3 = lnext(e2);
    if (lnext(e3) != e) return 0;
    int a = orig(e), b = dest(e), c = dest(e2);
    if (a == b || b == c || a == c || !ccw(a, b, c)) return 0;
    *cx = circle_center_x(a, b, c);
    *cy = circle_center_y(a, b, c);
    return 1;
}

static int64_t quantize(double value) { return (int64_t)floor(value * SCALE + 0.5); }

int64_t olden_voronoi(const int64_t *input, size_t length) {
    if (input == NULL || (length != 7 && length != 11)) return -1;
    int64_t count_value = input[0];
    if (count_value != 3 && count_value != 5) return -1;
    int count = (int)count_value;
    if (length != (size_t)(1 + 2 * count)) return -1;
    for (int i = 0; i < MAX_POINTS; ++i) { left_child[i] = -1; right_child[i] = -1; }
    for (int i = 0; i < count; ++i) {
        int64_t x = input[1 + 2 * i], y = input[2 + 2 * i];
        if (x < -8 || x > 8 || y < -8 || y > 8) return -1;
        points[i] = (Point){(double)x, (double)y, (double)(x * x + y * y)};
        if (i > 0 && points[i - 1].x >= points[i].x) return -1;
    }
    if (count == 3) left_child[1] = 0;
    else { left_child[2] = 1; right_child[2] = 3; left_child[1] = 0; }
    for (int a = 0; a < count; ++a) for (int b = a + 1; b < count; ++b)
        for (int c = b + 1; c < count; ++c) if (!ccw(a, b, c) && !ccw(a, c, b)) return -1;
    if (count == 5) {
        for (int a = 0; a < count; ++a) for (int b = a + 1; b < count; ++b)
            for (int c = b + 1; c < count; ++c) for (int d = c + 1; d < count; ++d)
                if (!incircle(a, b, c, d) && !incircle(a, c, b, d)) return -1;
    }

    edge_count = 0;
    EdgePair hull = build_delaunay(count == 3 ? 1 : 2, count - 1);
    (void)hull;
    int seen[16][3], face_count = 0, edge_total = 0, finite_dual_edges = 0, boundary_rays = 0;
    int64_t center_projection = 0;
    double centers_x[16], centers_y[16];
    for (int edge = 0; edge < edge_count; ++edge) if (alive[edge]) {
        int e = 4 * edge;
        double cx, cy;
        int has_left = face_center(e, &cx, &cy);
        if (has_left) {
            int a = orig(e), b = dest(e), c = dest(lnext(e));
            int duplicate = 0;
            for (int f = 0; f < face_count; ++f)
                if ((seen[f][0] == a || seen[f][1] == a || seen[f][2] == a) &&
                    (seen[f][0] == b || seen[f][1] == b || seen[f][2] == b) &&
                    (seen[f][0] == c || seen[f][1] == c || seen[f][2] == c)) duplicate = 1;
            if (!duplicate) {
                seen[face_count][0] = a; seen[face_count][1] = b; seen[face_count][2] = c;
                centers_x[face_count] = cx; centers_y[face_count] = cy; ++face_count;
                center_projection += quantize(cx) + 2 * quantize(cy);
            }
        }
        double right_x, right_y;
        int has_right = face_center(sym(e), &right_x, &right_y);
        if (has_left || has_right) {
            ++edge_total;
            if (has_left && has_right) ++finite_dual_edges;
            else ++boundary_rays;
        }
    }
    return center_projection + 100 * face_count + 10 * finite_dual_edges + boundary_rays + edge_total;
}
