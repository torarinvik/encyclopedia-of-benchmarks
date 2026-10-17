#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 66;
constexpr std::int64_t invalid_result = -1;

std::int64_t abs_i64(std::int64_t value)
{
    return value < 0 ? -value : value;
}

std::int64_t gcd_i64(std::int64_t a, std::int64_t b)
{
    while (b != 0) {
        const auto temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

std::int64_t cross(std::int64_t x1, std::int64_t y1, std::int64_t x2, std::int64_t y2)
{
    return x1 * y2 - x2 * y1;
}
}

extern "C" std::int64_t polygon_points(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || length > max_input_length) return invalid_result;
    const std::int64_t raw_n = values[0];
    if (raw_n < 3 || raw_n > 32 || length != 1 + 2 * static_cast<std::size_t>(raw_n)) return invalid_result;
    const auto n = static_cast<std::size_t>(raw_n);
    for (std::size_t i = 0; i < 2 * n; ++i) {
        if (values[1 + i] < -1000 || values[1 + i] > 1000) return invalid_result;
    }

    const auto origin_x = values[1], origin_y = values[2];
    std::int64_t doubled_area = 0;
    for (std::size_t i = 2; i < n; ++i) {
        const auto x1 = values[1 + 2 * i] - origin_x;
        const auto y1 = values[2 + 2 * i] - origin_y;
        const auto x2 = values[1 + 2 * (i - 1)] - origin_x;
        const auto y2 = values[2 + 2 * (i - 1)] - origin_y;
        doubled_area += cross(x1, y1, x2, y2);
    }
    const auto area = abs_i64(doubled_area / 2);

    std::int64_t boundary = raw_n;
    for (std::size_t i = 0; i < n; ++i) {
        const auto next = (i + 1) % n;
        const auto dx = values[1 + 2 * i] - values[1 + 2 * next];
        const auto dy = values[2 + 2 * i] - values[2 + 2 * next];
        boundary += abs_i64(gcd_i64(dx, dy)) - 1;
    }
    return area + 1 - boundary / 2;
}
