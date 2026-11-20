#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 32, max_queries = 16, max_input = 99, max_coordinate = 1000;
struct Point { std::int64_t x, y; };
Point sub(Point a, Point b) { return {a.x - b.x, a.y - b.y}; }
std::int64_t cross(Point a, Point b) { return a.x * b.y - a.y * b.x; }

bool valid_polygon(const Point* p, int n) {
    for (int i = 0; i < n; ++i) {
        const int next = (i + 1) % n;
        if (p[i].x == p[next].x && p[i].y == p[next].y) return false;
        const Point edge = sub(p[next], p[i]);
        for (int j = 0; j < n; ++j)
            if (j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0) return false;
    }
    return true;
}
bool valid_query(const Point* p, int n, Point q) {
    bool outside = false;
    for (int i = 0; i < n; ++i) {
        const auto side = cross(sub(p[(i + 1) % n], p[i]), sub(q, p[i]));
        if (side == 0) return false;
        if (side < 0) outside = true;
    }
    return outside;
}
int build_chain(int* chain, int n, int start, int stop) {
    int length = 0, at = start;
    for (;;) {
        chain[length++] = at;
        if (at == stop) return length;
        at = (at + 1) % n;
        if (length > n) return 0;
    }
}
bool build_layers(const Point* p, int n, int* lower, int& lower_len, int* upper, int& upper_len) {
    int min_x = 0, max_x = 0;
    for (int i = 1; i < n; ++i) {
        if (p[i].x < p[min_x].x) min_x = i;
        if (p[i].x > p[max_x].x) max_x = i;
    }
    int left_bottom = min_x, left_top = min_x, right_bottom = max_x, right_top = max_x;
    for (int i = 0; i < n; ++i) {
        if (p[i].x == p[min_x].x) {
            if (p[i].y < p[left_bottom].y) left_bottom = i;
            if (p[i].y > p[left_top].y) left_top = i;
        }
        if (p[i].x == p[max_x].x) {
            if (p[i].y < p[right_bottom].y) right_bottom = i;
            if (p[i].y > p[right_top].y) right_top = i;
        }
    }
    lower_len = build_chain(lower, n, left_bottom, right_bottom);
    upper_len = build_chain(upper, n, right_top, left_top);
    return lower_len != 0 && upper_len != 0;
}
int split_ascending(const Point* p, const int* chain, int length, std::int64_t qx) {
    int lo = 0, hi = length;
    while (lo < hi) {
        const int mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x < qx) lo = mid + 1; else hi = mid;
    }
    return lo == 0 ? 0 : lo - 1;
}
int split_descending(const Point* p, const int* chain, int length, std::int64_t qx) {
    int lo = 0, hi = length;
    while (lo < hi) {
        const int mid = lo + (hi - lo) / 2;
        if (p[chain[mid]].x > qx) lo = mid + 1; else hi = mid;
    }
    return lo == 0 ? 0 : lo - 1;
}
int tangent_search(const Point* p, int n, const int* chain, int lo, int hi, Point q, int sign) {
    int result = lo;
    while (lo <= hi) {
        const int mid = lo + (hi - lo) / 2;
        const int index = chain[mid];
        const Point here = sub(p[index], q);
        const auto to_next = sign * cross(here, sub(p[(index + 1) % n], q));
        const auto to_prev = sign * cross(here, sub(p[(index + n - 1) % n], q));
        if (to_next >= 0 && to_prev >= 0) return mid;
        if (to_next >= 0) { result = mid; hi = mid - 1; }
        else lo = mid + 1;
    }
    return result;
}
bool supports(const Point* p, int n, int index, Point q, int sign) {
    const Point here = sub(p[index], q);
    return sign * cross(here, sub(p[(index + n - 1) % n], q)) > 0 &&
           sign * cross(here, sub(p[(index + 1) % n], q)) > 0;
}
bool find_tangents(const Point* p, int n, const int* lower, int lower_len,
                   const int* upper, int upper_len, Point q, int& first, int& second) {
    const int lower_split = split_ascending(p, lower, lower_len, q.x);
    const int upper_split = split_descending(p, upper, upper_len, q.x);
    const int left_a = lower[tangent_search(p, n, lower, 0, lower_split, q, -1)];
    const int left_b = upper[tangent_search(p, n, upper, 0, upper_split, q, -1)];
    const int right_a = lower[tangent_search(p, n, lower, lower_split, lower_len - 1, q, 1)];
    const int right_b = upper[tangent_search(p, n, upper, upper_split, upper_len - 1, q, 1)];
    const int left = supports(p, n, left_a, q, -1) ? left_a :
                     supports(p, n, left_b, q, -1) ? left_b : -1;
    const int right = supports(p, n, right_a, q, 1) ? right_a :
                      supports(p, n, right_b, q, 1) ? right_b : -1;
    if (left < 0 || right < 0 || left == right) return false;
    first = left < right ? left : right;
    second = left < right ? right : left;
    return true;
}
void put_i64(std::uint8_t* out, std::size_t& offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset++] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t external_point_tangents_convex_polygon(
        const std::int64_t* v, std::size_t length, std::uint8_t* out, std::size_t capacity) noexcept {
    if (!v || length < 2 || length > max_input || v[0] < 3 || v[0] > max_vertices ||
        v[1] < 0 || v[1] > max_queries) return -1;
    const int n = static_cast<int>(v[0]), q_count = static_cast<int>(v[1]);
    if (length != static_cast<std::size_t>(2 + 2 * n + 2 * q_count)) return -1;
    Point polygon[max_vertices], queries[max_queries];
    std::int64_t answers[2 * max_queries];
    std::size_t at = 2;
    for (int i = 0; i < n; ++i) {
        polygon[i] = {v[at], v[at + 1]}; at += 2;
        if (polygon[i].x < -max_coordinate || polygon[i].x > max_coordinate ||
            polygon[i].y < -max_coordinate || polygon[i].y > max_coordinate) return -1;
    }
    if (!valid_polygon(polygon, n)) return -1;
    int lower[max_vertices], upper[max_vertices], lower_len, upper_len;
    if (!build_layers(polygon, n, lower, lower_len, upper, upper_len)) return -1;
    for (int i = 0; i < q_count; ++i) {
        queries[i] = {v[at], v[at + 1]}; at += 2;
        if (queries[i].x < -max_coordinate || queries[i].x > max_coordinate ||
            queries[i].y < -max_coordinate || queries[i].y > max_coordinate ||
            !valid_query(polygon, n, queries[i])) return -1;
        int first, second;
        if (!find_tangents(polygon, n, lower, lower_len, upper, upper_len,
                           queries[i], first, second)) return -1;
        answers[2 * i] = first;
        answers[2 * i + 1] = second;
    }
    const std::size_t needed = 16 * static_cast<std::size_t>(q_count);
    if (needed > capacity || !out) return -2;
    std::size_t offset = 0;
    for (int i = 0; i < 2 * q_count; ++i) put_i64(out, offset, answers[i]);
    return static_cast<std::int64_t>(needed);
}
