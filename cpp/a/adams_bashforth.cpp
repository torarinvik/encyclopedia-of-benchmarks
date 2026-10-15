// Bounded Adams-Bashforth methods for y' = x + y on a quarter-step grid.
#include <cstddef>
#include <cstdint>

static std::size_t append_integer(std::int64_t value, std::uint8_t *out, std::size_t position)
{
    std::uint8_t digits[24];
    std::size_t count = 0;
    if (value < 0) { out[position++] = '-'; value = -value; }
    do { digits[count++] = static_cast<std::uint8_t>(value % 10); value /= 10; } while (value > 0);
    while (count > 0) out[position++] = static_cast<std::uint8_t>('0' + digits[--count]);
    return position;
}

extern "C" std::int64_t adams_bashforth(const std::int64_t *values, std::size_t length,
                                         std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 4) return -1;
    const auto order_arg = values[0], steps_arg = values[1];
    if (order_arg < 2 || order_arg > 5 || steps_arg < 1 || steps_arg > 4 ||
        length != static_cast<std::size_t>(order_arg) + 2) return -1;
    const auto order = static_cast<std::size_t>(order_arg);
    const auto steps = static_cast<std::size_t>(steps_arg);
    double x[14], y[14];
    for (std::size_t i = 0; i < order; ++i) {
        if (values[i + 2] < -100000 || values[i + 2] > 100000) return -1;
        x[i] = static_cast<double>(i) * 0.25;
        y[i] = static_cast<double>(values[i + 2]) / 100000.0;
    }
    constexpr std::int64_t c2[] = {3, -1};
    constexpr std::int64_t c3[] = {23, -16, 5};
    constexpr std::int64_t c4[] = {55, -59, 37, -9};
    constexpr std::int64_t c5[] = {1901, -2774, -2616, -1274, 251};
    const auto *coefficients = order == 2 ? c2 : order == 3 ? c3 : order == 4 ? c4 : c5;
    const std::int64_t denominator = order == 2 ? 2 : order == 3 ? 12 : order == 4 ? 24 : 720;
    const auto iterations = steps + ((order == 3 || order == 5) ? 1 : 0);
    std::size_t count = order;
    for (std::size_t iteration = 0; iteration < iterations; ++iteration) {
        double weighted = 0.0;
        for (std::size_t offset = 0; offset < order; ++offset) {
            const auto index = count - 1 - offset;
            weighted += static_cast<double>(coefficients[offset]) * (x[index] + y[index]);
        }
        y[count] = y[count - 1] + (0.25 / static_cast<double>(denominator)) * weighted;
        x[count] = x[count - 1] + 0.25;
        ++count;
    }
    std::uint8_t encoded[256];
    std::size_t position = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (i != 0) encoded[position++] = ',';
        position = append_integer(static_cast<std::int64_t>(y[i] * 1000000.0), encoded, position);
    }
    if (output == nullptr || output_capacity < position) return -2;
    for (std::size_t i = 0; i < position; ++i) output[i] = encoded[i];
    return static_cast<std::int64_t>(position);
}
