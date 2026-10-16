#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_POINTS = 16;

double integer_power(double base, std::size_t exponent) noexcept {
    double result = 1.0;
    for (std::size_t index = 0; index < exponent; ++index) result *= base;
    return result;
}

std::uint64_t choose(std::size_t n, std::size_t k) noexcept {
    if (k > n - k) k = n - k;
    std::uint64_t result = 1;
    for (std::size_t index = 1; index <= k; ++index)
        result = result * (n - k + index) / index;
    return result;
}

std::int64_t round_scaled(double value) noexcept {
    const double scaled = value * 1000000.0;
    return static_cast<std::int64_t>(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bezier_curve(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 4 || length > 34) return -1;
    const auto point_count_value = values[0], parameter_q = values[1];
    if (point_count_value < 1 || point_count_value > static_cast<std::int64_t>(MAX_POINTS) ||
        parameter_q < 0 || parameter_q > 1000000 ||
        length != 2 + 2 * static_cast<std::size_t>(point_count_value)) return -1;
    const auto point_count = static_cast<std::size_t>(point_count_value);
    for (std::size_t index = 2; index < length; ++index)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    if (output == nullptr || output_capacity < 32) return -2;

    const auto degree = point_count - 1;
    const double t = static_cast<double>(parameter_q) / 1000000.0;
    double x = 0.0, y = 0.0, dx = 0.0, dy = 0.0;
    for (std::size_t index = 0; index < point_count; ++index) {
        const double weight = static_cast<double>(choose(degree, index)) *
            integer_power(1.0 - t, degree - index) * integer_power(t, index);
        x += weight * static_cast<double>(values[2 + 2 * index]);
        y += weight * static_cast<double>(values[3 + 2 * index]);
    }
    for (std::size_t index = 0; index < degree; ++index) {
        const double weight = static_cast<double>(degree) * static_cast<double>(choose(degree - 1, index)) *
            integer_power(1.0 - t, degree - 1 - index) * integer_power(t, index);
        dx += weight * static_cast<double>(values[4 + 2 * index] - values[2 + 2 * index]);
        dy += weight * static_cast<double>(values[5 + 2 * index] - values[3 + 2 * index]);
    }
    write_i64_le(output, 0, round_scaled(x));
    write_i64_le(output, 8, round_scaled(y));
    write_i64_le(output, 16, round_scaled(dx));
    write_i64_le(output, 24, round_scaled(dy));
    return 32;
}
