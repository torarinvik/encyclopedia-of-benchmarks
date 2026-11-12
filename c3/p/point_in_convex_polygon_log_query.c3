module point_in_convex_polygon_log_query;

const usz MAX_VERTICES = 32;
const usz MAX_QUERIES = 32;
const usz MAX_INPUT = 131;
const long MAX_COORD = 1000000;
struct Point { long x; long y; }

fn Point sub(Point a, Point b) { return Point{a.x - b.x, a.y - b.y}; }
fn long cross(Point a, Point b) { return a.x * b.y - a.y * b.x; }
fn bool on_segment(Point a, Point b, Point p) {
    Point e = sub(b, a), r = sub(p, a);
    return cross(e, r) == 0 && p.x >= (a.x < b.x ? a.x : b.x) && p.x <= (a.x > b.x ? a.x : b.x)
        && p.y >= (a.y < b.y ? a.y : b.y) && p.y <= (a.y > b.y ? a.y : b.y);
}
fn bool valid_polygon(Point* p, usz n) {
    for (usz i = 0; i < n; i++) {
        usz next = (i + 1) % n;
        if (p[i].x == p[next].x && p[i].y == p[next].y) return false;
        Point edge = sub(p[next], p[i]);
        for (usz j = 0; j < n; j++)
            if (j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0) return false;
        for (usz j = i + 1; j < n; j++)
            if (p[i].x == p[j].x && p[i].y == p[j].y) return false;
    }
    return true;
}
fn long contains_fan(Point* fan, usz m, Point query) {
    Point origin = Point{0, 0};
    long first = cross(fan[0], query), last = cross(fan[m - 1], query);
    if (first < 0 || last > 0) return 0;
    if (first == 0) return on_segment(origin, fan[0], query) ? 1 : 0;
    if (last == 0) return on_segment(origin, fan[m - 1], query) ? 1 : 0;
    usz lo = 0, hi = m;
    while (hi - lo > 1) {
        usz mid = (lo + hi) / 2;
        if (cross(fan[mid], query) >= 0) lo = mid; else hi = mid;
    }
    long side = cross(sub(fan[lo + 1], fan[lo]), sub(query, fan[lo]));
    if (side < 0) return 0;
    if (side == 0) return on_segment(fan[lo], fan[lo + 1], query) ? 1 : 0;
    return 1;
}
fn void put_i64(char* out, usz* offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { out[*offset] = (char)(bits >> (8 * b)); (*offset)++; }
}

fn long point_in_convex_polygon_log_query(long* v, usz n, char* out, usz cap)
    @export("point_in_convex_polygon_log_query") {
    if (v == null || n < 2 || n > MAX_INPUT || v[0] < 3 || v[0] > 32 || v[1] < 0 || v[1] > 32) return -1;
    usz vertices = (usz)v[0], queries = (usz)v[1];
    if (n != 2 + 2 * vertices + 2 * queries) return -1;
    Point[MAX_VERTICES] polygon = {}, fan = {};
    Point[MAX_QUERIES] query_points = {};
    long[MAX_QUERIES] answers = {};
    usz at = 2;
    for (usz i = 0; i < vertices; i++) {
        polygon[i] = Point{v[at], v[at + 1]}; at += 2;
        if (polygon[i].x < -MAX_COORD || polygon[i].x > MAX_COORD || polygon[i].y < -MAX_COORD || polygon[i].y > MAX_COORD) return -1;
    }
    if (!valid_polygon(&polygon[0], vertices)) return -1;
    for (usz i = 0; i < queries; i++) {
        query_points[i] = Point{v[at], v[at + 1]}; at += 2;
        if (query_points[i].x < -MAX_COORD || query_points[i].x > MAX_COORD || query_points[i].y < -MAX_COORD || query_points[i].y > MAX_COORD) return -1;
    }
    usz pivot = 0;
    for (usz i = 1; i < vertices; i++)
        if (polygon[i].x < polygon[pivot].x || (polygon[i].x == polygon[pivot].x && polygon[i].y < polygon[pivot].y)) pivot = i;
    for (usz i = 0; i + 1 < vertices; i++) fan[i] = sub(polygon[(pivot + i + 1) % vertices], polygon[pivot]);
    for (usz i = 0; i < queries; i++) answers[i] = contains_fan(&fan[0], vertices - 1, sub(query_points[i], polygon[pivot]));
    usz needed = 8 * queries;
    if (needed > cap || (needed != 0 && out == null)) return -2;
    usz offset = 0;
    for (usz i = 0; i < queries; i++) put_i64(out, &offset, answers[i]);
    return (long)needed;
}
