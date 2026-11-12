module minkowski_sum_convex_polygons;

const usz MAX_VERTICES = 32;
const usz MAX_INPUT = 131;
const long MAX_COORD = 1000000;
struct Point { long x; long y; }

fn long cross(Point a, Point b) { return a.x * b.y - a.y * b.x; }
fn Point edge(Point* p, usz n, usz i) {
    Point next = p[(i + 1) % n];
    return Point{next.x - p[i].x, next.y - p[i].y};
}
fn int half(Point v) { return v.y > 0 || (v.y == 0 && v.x >= 0) ? 0 : 1; }
fn int angle_compare(Point a, Point b) {
    int ha = half(a), hb = half(b);
    if (ha != hb) return ha < hb ? -1 : 1;
    long turn = cross(a, b);
    return turn > 0 ? -1 : (turn < 0 ? 1 : 0);
}
fn bool valid_polygon(Point* p, usz n) {
    usz wraps = 0;
    for (usz i = 0; i < n; i++) {
        Point a = edge(p, n, i), b = edge(p, n, (i + 1) % n);
        if ((a.x == 0 && a.y == 0) || cross(a, b) <= 0) return false;
        if (angle_compare(b, a) < 0) wraps++;
    }
    return wraps == 1;
}
fn void rotate_lowest(Point* p, usz n) {
    usz first = 0;
    for (usz i = 1; i < n; i++)
        if (p[i].y < p[first].y || (p[i].y == p[first].y && p[i].x < p[first].x)) first = i;
    Point[MAX_VERTICES] tmp = {};
    for (usz i = 0; i < n; i++) tmp[i] = p[(first + i) % n];
    for (usz i = 0; i < n; i++) p[i] = tmp[i];
}
fn void put_i64(char* out, usz* offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { out[*offset] = (char)(bits >> (8 * b)); (*offset)++; }
}

fn long minkowski_sum_convex_polygons(long* v, usz n, char* out, usz cap)
    @export("minkowski_sum_convex_polygons") {
    if (v == null || n < 14 || n > MAX_INPUT || v[0] < 3 || v[0] > 32 || v[1] < 3 || v[1] > 32) return -1;
    usz pn = (usz)v[0], qn = (usz)v[1];
    if (n != 2 + 2 * pn + 2 * qn) return -1;
    Point[MAX_VERTICES] p = {}, q = {};
    Point[MAX_VERTICES * 2] sums = {};
    usz at = 2;
    for (usz i = 0; i < pn; i++) {
        p[i] = Point{v[at], v[at + 1]}; at += 2;
        if (p[i].x < -MAX_COORD || p[i].x > MAX_COORD || p[i].y < -MAX_COORD || p[i].y > MAX_COORD) return -1;
    }
    for (usz i = 0; i < qn; i++) {
        q[i] = Point{v[at], v[at + 1]}; at += 2;
        if (q[i].x < -MAX_COORD || q[i].x > MAX_COORD || q[i].y < -MAX_COORD || q[i].y > MAX_COORD) return -1;
    }
    if (!valid_polygon(&p[0], pn) || !valid_polygon(&q[0], qn)) return -1;
    rotate_lowest(&p[0], pn); rotate_lowest(&q[0], qn);
    usz i = 0, j = 0, count = 0;
    while (i < pn || j < qn) {
        sums[count++] = Point{p[i % pn].x + q[j % qn].x, p[i % pn].y + q[j % qn].y};
        if (i == pn) { j++; continue; }
        if (j == qn) { i++; continue; }
        int order = angle_compare(edge(&p[0], pn, i), edge(&q[0], qn, j));
        if (order <= 0) i++;
        if (order >= 0) j++;
    }
    usz needed = (1 + 2 * count) * 8;
    if (needed > cap || out == null) return -2;
    usz offset = 0;
    put_i64(out, &offset, (long)count);
    for (usz k = 0; k < count; k++) { put_i64(out, &offset, sums[k].x); put_i64(out, &offset, sums[k].y); }
    return (long)needed;
}
