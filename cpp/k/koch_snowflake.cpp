#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_POINTS = 29;
struct Point { float x, y; };
inline float add32(float a, float b) noexcept { return a + b; }
inline float sub32(float a, float b) noexcept { return a - b; }
inline float mul32(float a, float b) noexcept { return a * b; }
inline float div32(float a, float b) noexcept { return a / b; }
}

extern "C" std::int64_t koch_snowflake(const double *input, std::size_t length,
    double *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 20) return -1;
    if (!std::isfinite(input[0]) || std::floor(input[0]) != input[0] || input[0] < 0 || input[0] > 1 ||
        !std::isfinite(input[1]) || std::floor(input[1]) != input[1] || input[1] < 2 || input[1] > 8) return -1;
    const auto steps = static_cast<std::size_t>(input[0]);
    const auto point_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * point_count) return -1;
    for (std::size_t i = 0; i < 2 * point_count; ++i)
        if (!std::isfinite(input[i + 2]) || std::abs(input[i + 2]) > 1000.0) return -1;
    const std::size_t result_points = steps == 0 ? point_count : 4 * (point_count - 1) + 1;
    const std::size_t result_count = 2 * result_points;
    if (output == nullptr || output_capacity < result_count) return -2;

    Point first[MAX_POINTS]{}, second[MAX_POINTS]{};
    for (std::size_t i = 0; i < point_count; ++i)
        first[i] = {static_cast<float>(input[2 + 2 * i]), static_cast<float>(input[3 + 2 * i])};
    Point *source = first, *destination = second;
    std::size_t source_count = point_count;
    constexpr float two = 2.0f, cosine = 0.49999997f, sine = 0.86602545f;
    for (std::size_t step = 0; step < steps; ++step) {
        std::size_t cursor = 0;
        for (std::size_t i = 0; i + 1 < source_count; ++i) {
            const Point start = source[i], end = source[i + 1];
            const float dx = sub32(end.x, start.x), dy = sub32(end.y, start.y);
            const float tx = div32(dx, 3.0f), ty = div32(dy, 3.0f);
            const float first_x = add32(start.x, tx), first_y = add32(start.y, ty);
            const float rx = sub32(mul32(cosine, tx), mul32(sine, ty));
            const float ry = add32(mul32(sine, tx), mul32(cosine, ty));
            const float peak_x = add32(first_x, rx), peak_y = add32(first_y, ry);
            const float tx2 = div32(mul32(dx, two), 3.0f), ty2 = div32(mul32(dy, two), 3.0f);
            destination[cursor++] = start;
            destination[cursor++] = {first_x, first_y};
            destination[cursor++] = {peak_x, peak_y};
            destination[cursor++] = {add32(start.x, tx2), add32(start.y, ty2)};
        }
        destination[cursor++] = source[source_count - 1];
        source_count = cursor;
        Point *swap = source; source = destination; destination = swap;
    }
    for (std::size_t i = 0; i < result_points; ++i) {
        output[2 * i] = static_cast<double>(source[i].x);
        output[2 * i + 1] = static_cast<double>(source[i].y);
    }
    return static_cast<std::int64_t>(result_count);
}
