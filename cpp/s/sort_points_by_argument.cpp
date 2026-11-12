#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;
constexpr std::size_t INPUT_MAX = 1 + 2 * MAX_N;
struct Point { std::int64_t x, y; };

int half(const Point& p) {
    if (p.y < 0) return 0;
    if (p.y == 0 && p.x >= 0) return 1;
    return 2;
}
std::int64_t cross(const Point& a, const Point& b) { return a.x * b.y - a.y * b.x; }
std::int64_t radius2(const Point& p) { return p.x * p.x + p.y * p.y; }
bool argument_less(const Point& a, const Point& b) {
    const int ha = half(a), hb = half(b);
    if (ha != hb) return ha < hb;
    const auto determinant = cross(a, b);
    if (determinant != 0) return determinant > 0;
    const auto ra = radius2(a), rb = radius2(b);
    if (ra != rb) return ra < rb;
    if (a.x != b.x) return a.x < b.x;
    return a.y < b.y;
}
void store(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t sort_points_by_argument(const std::int64_t* input, std::size_t length,
                                                  std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 1 || length > INPUT_MAX) return -1;
    const auto nr = input[0];
    if (nr < 1 || nr > static_cast<std::int64_t>(MAX_N) || length != 1 + 2 * static_cast<std::size_t>(nr)) return -1;
    const auto n = static_cast<std::size_t>(nr);
    std::array<Point, MAX_N> points{};
    for (std::size_t i = 0; i < n; ++i) {
        points[i] = {input[1 + 2 * i], input[2 + 2 * i]};
        if (points[i].x < -1000000000 || points[i].x > 1000000000 || points[i].y < -1000000000 || points[i].y > 1000000000) return -1;
    }
    const std::size_t required = 16 * n;
    if (!output || capacity < required) return -2;
    std::sort(points.begin(), points.begin() + static_cast<std::ptrdiff_t>(n), argument_less);
    std::array<std::int64_t, 2 * MAX_N> staged{};
    for (std::size_t i = 0; i < n; ++i) { staged[2 * i] = points[i].x; staged[2 * i + 1] = points[i].y; }
    for (std::size_t i = 0; i < 2 * n; ++i) store(output, 8 * i, staged[i]);
    return static_cast<std::int64_t>(required);
}
