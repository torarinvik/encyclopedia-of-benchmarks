#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t kMaxVertices = 64;

std::int64_t orient(const std::int64_t* v, std::size_t a, std::size_t b, std::size_t c) noexcept {
    const auto abx = v[2 * b] - v[2 * a];
    const auto aby = v[2 * b + 1] - v[2 * a + 1];
    const auto acx = v[2 * c] - v[2 * a];
    const auto acy = v[2 * c + 1] - v[2 * a + 1];
    return abx * acy - aby * acx;
}

bool on_segment(const std::int64_t* v, std::size_t a, std::size_t b, std::size_t p) noexcept {
    return v[2 * p] >= (v[2 * a] < v[2 * b] ? v[2 * a] : v[2 * b]) &&
           v[2 * p] <= (v[2 * a] > v[2 * b] ? v[2 * a] : v[2 * b]) &&
           v[2 * p + 1] >= (v[2 * a + 1] < v[2 * b + 1] ? v[2 * a + 1] : v[2 * b + 1]) &&
           v[2 * p + 1] <= (v[2 * a + 1] > v[2 * b + 1] ? v[2 * a + 1] : v[2 * b + 1]);
}

bool segments_intersect(const std::int64_t* v, std::size_t a, std::size_t b,
                        std::size_t c, std::size_t d) noexcept {
    const auto o1 = orient(v, a, b, c), o2 = orient(v, a, b, d);
    const auto o3 = orient(v, c, d, a), o4 = orient(v, c, d, b);
    if (((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) &&
        ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0))) return true;
    return (o1 == 0 && on_segment(v, a, b, c)) ||
           (o2 == 0 && on_segment(v, a, b, d)) ||
           (o3 == 0 && on_segment(v, c, d, a)) ||
           (o4 == 0 && on_segment(v, c, d, b));
}

bool in_triangle(const std::int64_t* v, std::size_t a, std::size_t b, std::size_t c,
                 std::size_t p, int winding) noexcept {
    return orient(v, a, b, p) * winding >= 0 &&
           orient(v, b, c, p) * winding >= 0 &&
           orient(v, c, a, p) * winding >= 0;
}

void write_u32_le(std::uint8_t* out, std::size_t position, std::size_t index) noexcept {
    const auto value = static_cast<std::uint32_t>(index);
    for (std::size_t byte = 0; byte < 4; ++byte)
        out[4 * position + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t ear_clipping_polygon_triangulation(
    const std::int64_t* values, std::size_t length, std::uint8_t* output,
    std::size_t output_capacity) noexcept {
    if (length % 2 != 0 || length / 2 < 3 || length / 2 > kMaxVertices || values == nullptr) return -1;
    const std::size_t n = length / 2;
    std::int64_t area2 = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::size_t next = (i + 1) % n;
        if (values[2 * i] < -10000 || values[2 * i] > 10000 ||
            values[2 * i + 1] < -10000 || values[2 * i + 1] > 10000) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (values[2 * i] == values[2 * j] && values[2 * i + 1] == values[2 * j + 1]) return -1;
        area2 += values[2 * i] * values[2 * next + 1] - values[2 * i + 1] * values[2 * next];
        if (orient(values, (i + n - 1) % n, i, next) == 0) return -1;
    }
    if (area2 == 0) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        const std::size_t inext = (i + 1) % n;
        for (std::size_t j = i + 1; j < n; ++j) {
            const std::size_t jnext = (j + 1) % n;
            if (inext == j || jnext == i) continue;
            if (segments_intersect(values, i, inext, j, jnext)) return -1;
        }
    }
    if (output == nullptr || output_capacity < 12 * (n - 2)) return -2;

    const int winding = area2 > 0 ? 1 : -1;
    std::vector<bool> live(n, true);
    std::size_t live_count = n, emitted = 0;
    while (live_count > 3) {
        bool clipped = false;
        for (std::size_t current = 0; current < n; ++current) {
            if (!live[current]) continue;
            std::size_t prev = (current + n - 1) % n, next = (current + 1) % n;
            while (!live[prev]) prev = (prev + n - 1) % n;
            while (!live[next]) next = (next + 1) % n;
            if (orient(values, prev, current, next) * winding <= 0) continue;
            bool contains = false;
            for (std::size_t point = 0; point < n; ++point) {
                if (live[point] && point != prev && point != current && point != next &&
                    in_triangle(values, prev, current, next, point, winding)) {
                    contains = true;
                    break;
                }
            }
            if (contains) continue;
            write_u32_le(output, emitted++, prev);
            write_u32_le(output, emitted++, current);
            write_u32_le(output, emitted++, next);
            live[current] = false;
            --live_count;
            clipped = true;
            break;
        }
        if (!clipped) return -1;
    }
    std::size_t first = 0;
    while (!live[first]) ++first;
    std::size_t second = (first + 1) % n;
    while (!live[second]) second = (second + 1) % n;
    std::size_t third = (second + 1) % n;
    while (!live[third]) third = (third + 1) % n;
    write_u32_le(output, emitted++, first);
    write_u32_le(output, emitted++, second);
    write_u32_le(output, emitted++, third);
    return static_cast<std::int64_t>(n - 2);
}
