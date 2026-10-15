#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_COORD = 128, MAX_STEPS = 256;
std::int64_t java_round(double value) {
    const double shifted = value + 0.5;
    auto rounded = static_cast<std::int64_t>(shifted);
    if (static_cast<double>(rounded) > shifted) --rounded;
    return rounded;
}
void write_i64(std::uint8_t *output, std::size_t &position, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) output[position++] = static_cast<std::uint8_t>(bits >> shift);
}
}
extern "C" std::int64_t ddaline(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 4) return -1;
    for (std::size_t i = 0; i < 4; ++i) if (input[i] < -MAX_COORD || input[i] > MAX_COORD) return -1;
    const auto dx = input[2] - input[0], dy = input[3] - input[1];
    const auto ax = dx < 0 ? -dx : dx, ay = dy < 0 ? -dy : dy;
    const auto steps = ax > ay ? ax : ay;
    if (steps > MAX_STEPS) return -1;
    const auto output_bytes = (static_cast<std::size_t>(steps) + 1) * 16;
    if (output == nullptr || capacity < output_bytes) return -2;
    if (steps == 0) {
        std::size_t position = 0;
        write_i64(output, position, input[0]);
        write_i64(output, position, input[1]);
        return 16;
    }
    const double x_inc = static_cast<double>(dx) / static_cast<double>(steps);
    const double y_inc = static_cast<double>(dy) / static_cast<double>(steps);
    double x = static_cast<double>(input[0]), y = static_cast<double>(input[1]);
    std::size_t position = 0;
    for (std::int64_t i = 0; i <= steps; ++i) {
        write_i64(output, position, java_round(x));
        write_i64(output, position, java_round(y));
        x += x_inc;
        y += y_inc;
    }
    return static_cast<std::int64_t>(output_bytes);
}
