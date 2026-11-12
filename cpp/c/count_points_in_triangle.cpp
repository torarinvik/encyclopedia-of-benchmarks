#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 24, MAX_M = 24, MAX_Q = 128, INPUT_MAX = 483;
struct Point { std::int64_t x, y; };
struct Vec { std::int64_t x, y; };
struct Query { std::int64_t a, b, c; };

int half(Vec v) { if (v.y < 0) return 0; if (v.y == 0 && v.x >= 0) return 1; return 2; }
bool angle_less(Vec a, Vec b) {
    const int ha = half(a), hb = half(b);
    if (ha != hb) return ha < hb;
    return a.x * b.y - a.y * b.x > 0;
}
bool direction_less(Vec a, Vec b) {
    if (angle_less(a, b)) return true;
    if (angle_less(b, a)) return false;
    const auto ra = a.x * a.x + a.y * a.y, rb = b.x * b.x + b.y * b.y;
    if (ra != rb) return ra < rb;
    if (a.x != b.x) return a.x < b.x;
    return a.y < b.y;
}
void sort_vectors(Vec* values, std::size_t count) {
    for (std::size_t i = 1; i < count; ++i) {
        const Vec item = values[i];
        std::size_t j = i;
        while (j > 0 && direction_less(item, values[j - 1])) { values[j] = values[j - 1]; --j; }
        values[j] = item;
    }
}
std::size_t lower_bound_ray(const Vec* values, std::size_t count, Vec ray) {
    std::size_t low = 0, high = count;
    while (low < high) { const auto mid = low + (high - low) / 2; if (angle_less(values[mid], ray)) low = mid + 1; else high = mid; }
    return low;
}
std::size_t upper_bound_ray(const Vec* values, std::size_t count, Vec ray) {
    std::size_t low = 0, high = count;
    while (low < high) { const auto mid = low + (high - low) / 2; if (!angle_less(ray, values[mid])) low = mid + 1; else high = mid; }
    return low;
}
int fenwick_prefix(const int* tree, std::size_t end) {
    int total = 0; while (end > 0) { total += tree[end]; end &= end - 1; } return total;
}
int count_arc(const Vec* dirs, std::size_t count, const int* tree, Vec start, Vec end) {
    const auto left = lower_bound_ray(dirs, count, start), right = upper_bound_ray(dirs, count, end);
    if (!angle_less(end, start)) return fenwick_prefix(tree, right) - fenwick_prefix(tree, left);
    return fenwick_prefix(tree, count) - fenwick_prefix(tree, left) + fenwick_prefix(tree, right);
}
int halfplane_count(std::size_t u, std::size_t v, const std::array<Point, MAX_N>& a,
                    const std::array<std::array<Vec, MAX_M>, MAX_N>& dirs,
                    const std::array<std::size_t, MAX_N>& counts,
                    const std::array<std::array<int, MAX_M + 1>, MAX_N>& bit) {
    const Vec edge{a[v].x - a[u].x, a[v].y - a[u].y};
    return static_cast<int>(counts[u]) + count_arc(dirs[u].data(), counts[u], bit[u].data(), {-edge.x, -edge.y}, edge);
}
void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t count_points_in_triangle(const std::int64_t* input, std::size_t length,
                                                  std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 3 || length > INPUT_MAX) return -1;
    const auto nr = input[0], mr = input[1], qr = input[2];
    if (nr < 1 || nr > static_cast<std::int64_t>(MAX_N) || mr < 1 || mr > static_cast<std::int64_t>(MAX_M) || qr < 1 || qr > static_cast<std::int64_t>(MAX_Q)) return -1;
    const auto n = static_cast<std::size_t>(nr), m = static_cast<std::size_t>(mr), q = static_cast<std::size_t>(qr);
    if (length != 3 + 2 * n + 2 * m + 3 * q) return -1;
    std::array<Point, MAX_N> a{};
    std::array<Point, MAX_M> b{};
    std::array<Query, MAX_Q> queries{};
    std::size_t cursor = 3;
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = {input[cursor], input[cursor + 1]}; cursor += 2;
        if (a[i].x < -1000000000 || a[i].x > 1000000000 || a[i].y < -1000000000 || a[i].y > 1000000000) return -1;
    }
    for (std::size_t i = 0; i < m; ++i) {
        b[i] = {input[cursor], input[cursor + 1]}; cursor += 2;
        if (b[i].x < -1000000000 || b[i].x > 1000000000 || b[i].y < -1000000000 || b[i].y > 1000000000) return -1;
    }
    for (std::size_t i = 0; i < q; ++i) {
        const auto ia = input[cursor], ib = input[cursor + 1], ic = input[cursor + 2]; cursor += 3;
        if (ia < 0 || ia >= nr || ib < 0 || ib >= nr || ic < 0 || ic >= nr) return -1;
        queries[i] = {ia, ib, ic};
    }
    const auto required = 8 * q;
    if (!output || capacity < required) return -2;

    std::array<std::array<Vec, MAX_M>, MAX_N> dirs{};
    std::array<std::size_t, MAX_N> counts{};
    std::array<int, MAX_N> zeros{};
    std::array<std::array<int, MAX_M + 1>, MAX_N> bit{};
    for (std::size_t u = 0; u < n; ++u) {
        for (std::size_t j = 0; j < m; ++j) {
            const Vec v{b[j].x - a[u].x, b[j].y - a[u].y};
            if (v.x == 0 && v.y == 0) ++zeros[u]; else dirs[u][counts[u]++] = v;
        }
        sort_vectors(dirs[u].data(), counts[u]);
        for (std::size_t i = 0; i < counts[u]; ++i)
            for (std::size_t at = i + 1; at <= counts[u]; at += at & (~at + 1)) ++bit[u][at];
    }
    std::array<std::int64_t, MAX_Q> answers{};
    for (std::size_t qi = 0; qi < q; ++qi) {
        std::size_t ia = static_cast<std::size_t>(queries[qi].a), ib = static_cast<std::size_t>(queries[qi].b), ic = static_cast<std::size_t>(queries[qi].c);
        const auto orient = (a[ib].x-a[ia].x)*(a[ic].y-a[ia].y) - (a[ib].y-a[ia].y)*(a[ic].x-a[ia].x);
        if (orient == 0) { answers[qi] = 0; continue; }
        if (orient < 0) { const auto tmp = ib; ib = ic; ic = tmp; }
        const int outside = halfplane_count(ia,ib,a,dirs,counts,bit) + halfplane_count(ib,ic,a,dirs,counts,bit) + halfplane_count(ic,ia,a,dirs,counts,bit);
        const Vec b_start{a[ib].x-a[ic].x,a[ib].y-a[ic].y}, b_end{a[ib].x-a[ia].x,a[ib].y-a[ia].y};
        const Vec c_start{a[ic].x-a[ia].x,a[ic].y-a[ia].y}, c_end{a[ic].x-a[ib].x,a[ic].y-a[ib].y};
        const Vec a_start{a[ia].x-a[ib].x,a[ia].y-a[ib].y}, a_end{a[ia].x-a[ic].x,a[ia].y-a[ic].y};
        const int pairs = zeros[ib]+count_arc(dirs[ib].data(),counts[ib],bit[ib].data(),b_start,b_end)
                        + zeros[ic]+count_arc(dirs[ic].data(),counts[ic],bit[ic].data(),c_start,c_end)
                        + zeros[ia]+count_arc(dirs[ia].data(),counts[ia],bit[ia].data(),a_start,a_end);
        answers[qi] = static_cast<std::int64_t>(m) - outside + pairs;
    }
    for (std::size_t i = 0; i < q; ++i) store_le(output, 8 * i, answers[i]);
    return static_cast<std::int64_t>(required);
}
