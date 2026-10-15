// Incremental floating-point DDA line points encoded as little-endian i32 pairs.
#include <cstddef>
#include <cstdint>

namespace {
std::int64_t round_ties_to_even(double value) noexcept {
    auto lower = static_cast<std::int64_t>(value);
    if (static_cast<double>(lower) > value) --lower;
    const double fraction = value - static_cast<double>(lower);
    if (fraction > 0.5 || (fraction == 0.5 && lower % 2 != 0)) ++lower;
    return lower;
}

void write_i32_le(std::uint8_t* output, std::size_t& position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (unsigned shift = 0; shift < 32; shift += 8) output[position++] = static_cast<std::uint8_t>(bits >> shift);
}
}

extern "C" std::int64_t digital_differential_analyzer_line(const std::int64_t* values, std::size_t length,
                                                              std::uint8_t* output, std::size_t output_capacity) noexcept {
    constexpr std::int64_t max_coordinate = 1'000'000, max_steps = 4096;
    if (length != 4) return -1;
    for (std::size_t i = 0; i < 4; ++i) if (values[i] < -max_coordinate || values[i] > max_coordinate) return -1;
    const auto dx = values[2] - values[0], dy = values[3] - values[1];
    const auto abs_dx = dx < 0 ? -dx : dx, abs_dy = dy < 0 ? -dy : dy;
    const auto steps = abs_dx > abs_dy ? abs_dx : abs_dy;
    if (steps == 0 || steps > max_steps) return -1;
    const auto output_bytes = static_cast<std::size_t>(steps) * 8;
    if (output_capacity < output_bytes || output == nullptr) return -2;
    const double x_increment = static_cast<double>(dx) / static_cast<double>(steps);
    const double y_increment = static_cast<double>(dy) / static_cast<double>(steps);
    double x = static_cast<double>(values[0]), y = static_cast<double>(values[1]);
    std::size_t position = 0;
    for (std::int64_t step = 0; step < steps; ++step) {
        x += x_increment;
        y += y_increment;
        write_i32_le(output, position, round_ties_to_even(x));
        write_i32_le(output, position, round_ties_to_even(y));
    }
    return static_cast<std::int64_t>(output_bytes);
}
