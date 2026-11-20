module external_point_tangents_convex_polygon;

const int MAX_VERTICES = 32;
const int MAX_QUERIES = 16;
const usz MAX_INPUT = 99;
const long MAX_COORDINATE = 1000;
struct Point { long x; long y; }

fn Point sub(Point a, Point b) { return Point{a.x - b.x, a.y - b.y}; }
fn long cross(Point a, Point b) { return a.x * b.y - a.y * b.x; }

fn bool valid_polygon(Point* p, int n) {
    for (int i = 0; i < n; i++) {
        int next = (i + 1) % n;
        if (p[i].x == p[next].x && p[i].y == p[next].y) return false;
        Point edge = sub(p[next], p[i]);
        for (int j = 0; j < n; j++)
            if (j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0) return false;
    }
    return true;
}
fn bool valid_query(Point* p, int n, Point q) {
    bool outside = false;
    for (int i = 0; i < n; i++) {
        long side = cross(sub(p[(i + 1) % n], p[i]), sub(q, p[i]));
        if (side == 0) return false;
        if (side < 0) outside = true;
    }
    return outside;
}
fn int build_chain(int* chain, int n, int start, int stop) {
    int length = 0, at = start;
    while (true) {
        chain[length++] = at;
        if (at == stop) return length;
        at = (at + 1) % n;
        if (length > n) return 0;
    }
}
fn bool build_layers(Point* p, int n, int* lower, int* lower_len, int* upper, int* upper_len) {
    int min_x = 0, max_x = 0;
    for (int i = 1; i < n; i++) {
        if (p[i].x < p[min_x].x) min_x = i;
        if (p[i].x > p[max_x].x) max_x = i;
    }
    int left_bottom = min_x, left_top = min_x, right_bottom = max_x, right_top = max_x;
    for (int i = 0; i < n; i++) {
        if (p[i].x == p[min_x].x) {
            if (p[i].y < p[left_bottom].y) left_bottom = i;
            if (p[i].y > p[left_top].y) left_top = i;
        }
        if (p[i].x == p[max_x].x) {
            if (p[i].y < p[right_bottom].y) right_bottom = i;
            if (p[i].y > p[right_top].y) right_top = i;
        }
    }
    *lower_len = build_chain(lower, n, left_bottom, right_bottom);
    *upper_len = build_chain(upper, n, right_top, left_top);
    return *lower_len != 0 && *upper_len != 0;
}
fn int split_ascending(Point* p, int* chain, int length, long qx) {
    int lo = 0, hi = length;
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x < qx) lo = mid + 1; else hi = mid;
    }
    return lo == 0 ? 0 : lo - 1;
}
fn int split_descending(Point* p, int* chain, int length, long qx) {
    int lo = 0, hi = length;
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x > qx) lo = mid + 1; else hi = mid;
    }
    return lo == 0 ? 0 : lo - 1;
}
fn int tangent_search(Point* p, int n, int* chain, int lo, int hi, Point q, int sign) {
    int result = lo;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int index = chain[mid];
        Point here = sub(p[index], q);
        long to_next = sign * cross(here, sub(p[(index + 1) % n], q));
        long to_prev = sign * cross(here, sub(p[(index + n - 1) % n], q));
        if (to_next >= 0 && to_prev >= 0) return mid;
        if (to_next >= 0) { result = mid; hi = mid - 1; }
        else lo = mid + 1;
    }
    return result;
}
fn bool supports(Point* p, int n, int index, Point q, int sign) {
    Point here = sub(p[index], q);
    return sign * cross(here, sub(p[(index + n - 1) % n], q)) > 0 &&
        sign * cross(here, sub(p[(index + 1) % n], q)) > 0;
}
fn bool find_tangents(Point* p, int n, int* lower, int lower_len, int* upper, int upper_len,
        Point q, int* first, int* second) {
    int lower_split = split_ascending(p, lower, lower_len, q.x);
    int upper_split = split_descending(p, upper, upper_len, q.x);
    int left_a = lower[tangent_search(p, n, lower, 0, lower_split, q, -1)];
    int left_b = upper[tangent_search(p, n, upper, 0, upper_split, q, -1)];
    int right_a = lower[tangent_search(p, n, lower, lower_split, lower_len - 1, q, 1)];
    int right_b = upper[tangent_search(p, n, upper, upper_split, upper_len - 1, q, 1)];
    int left = supports(p, n, left_a, q, -1) ? left_a : supports(p, n, left_b, q, -1) ? left_b : -1;
    int right = supports(p, n, right_a, q, 1) ? right_a : supports(p, n, right_b, q, 1) ? right_b : -1;
    if (left < 0 || right < 0 || left == right) return false;
    *first = left < right ? left : right;
    *second = left < right ? right : left;
    return true;
}
fn void put_i64(char* out, usz* offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { out[*offset] = (char)(bits >> (8 * b)); (*offset)++; }
}

fn long external_point_tangents_convex_polygon(long* v, usz length, char* out, usz capacity)
    @export("external_point_tangents_convex_polygon") {
    if (v == null || length < 2 || length > MAX_INPUT || v[0] < 3 || v[0] > MAX_VERTICES ||
        v[1] < 0 || v[1] > MAX_QUERIES) return -1;
    int n = (int)v[0], q_count = (int)v[1];
    if (length != (usz)(2 + 2 * n + 2 * q_count)) return -1;
    Point[MAX_VERTICES] polygon = {};
    Point[MAX_QUERIES] queries = {};
    long[2 * MAX_QUERIES] answers = {};
    usz at = 2;
    for (int i = 0; i < n; i++) {
        polygon[i] = Point{v[at], v[at + 1]}; at += 2;
        if (polygon[i].x < -MAX_COORDINATE || polygon[i].x > MAX_COORDINATE ||
            polygon[i].y < -MAX_COORDINATE || polygon[i].y > MAX_COORDINATE) return -1;
    }
    if (!valid_polygon(&polygon[0], n)) return -1;
    int[MAX_VERTICES] lower = {}, upper = {};
    int lower_len, upper_len;
    if (!build_layers(&polygon[0], n, &lower[0], &lower_len, &upper[0], &upper_len)) return -1;
    for (int i = 0; i < q_count; i++) {
        queries[i] = Point{v[at], v[at + 1]}; at += 2;
        if (queries[i].x < -MAX_COORDINATE || queries[i].x > MAX_COORDINATE ||
            queries[i].y < -MAX_COORDINATE || queries[i].y > MAX_COORDINATE ||
            !valid_query(&polygon[0], n, queries[i])) return -1;
        int first, second;
        if (!find_tangents(&polygon[0], n, &lower[0], lower_len, &upper[0], upper_len,
                queries[i], &first, &second)) return -1;
        answers[2 * i] = first;
        answers[2 * i + 1] = second;
    }
    usz needed = 16 * (usz)q_count;
    if (needed > capacity || out == null) return -2;
    usz offset = 0;
    for (int i = 0; i < 2 * q_count; i++) put_i64(out, &offset, answers[i]);
    return (long)needed;
}
