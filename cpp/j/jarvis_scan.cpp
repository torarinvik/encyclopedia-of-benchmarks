/* Return an integer Jarvis-scan hull in counter-clockwise order. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 64;
constexpr std::int64_t min_coordinate = -10000;
constexpr std::int64_t max_coordinate = 10000;

std::int64_t orientation(std::int64_t ax, std::int64_t ay, std::int64_t bx,
                         std::int64_t by, std::int64_t cx, std::int64_t cy) noexcept
{
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t jarvis_scan(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > 64) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * count) return -1;

    std::array<std::int64_t, max_points> x{}, y{};
    for (std::size_t point = 0; point < count; ++point) {
        x[point] = input[1 + 2 * point];
        y[point] = input[2 + 2 * point];
        if (x[point] < min_coordinate || x[point] > max_coordinate ||
            y[point] < min_coordinate || y[point] > max_coordinate) return -1;
    }
    if (count <= 2) return 0;
    for (std::size_t first = 0; first < count; ++first) {
        for (std::size_t second = first + 1; second < count; ++second) {
            if (x[first] == x[second] && y[first] == y[second]) return -1;
        }
    }
    for (std::size_t first = 0; first + 2 < count; ++first) {
        for (std::size_t second = first + 1; second + 1 < count; ++second) {
            for (std::size_t third = second + 1; third < count; ++third) {
                if (orientation(x[first], y[first], x[second], y[second], x[third], y[third]) == 0) return -1;
            }
        }
    }

    std::size_t start = 0;
    for (std::size_t point = 1; point < count; ++point) {
        if (x[point] < x[start] || (x[point] == x[start] && y[point] < y[start])) start = point;
    }
    std::array<std::size_t, max_points> hull{};
    std::size_t hull_count = 0, current = start;
    for (;;) {
        if (hull_count == count) return -1;
        hull[hull_count++] = current;
        std::size_t candidate = (current + 1) % count;
        for (std::size_t point = 0; point < count; ++point) {
            if (orientation(x[current], y[current], x[point], y[point], x[candidate], y[candidate]) > 0) candidate = point;
        }
        if (candidate == start) break;
        current = candidate;
    }
    const auto bytes = hull_count * 16;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t index = 0; index < hull_count; ++index) {
        put_i64(output, index * 16, x[hull[index]]);
        put_i64(output, index * 16 + 8, y[hull[index]]);
    }
    return static_cast<std::int64_t>(bytes);
}
