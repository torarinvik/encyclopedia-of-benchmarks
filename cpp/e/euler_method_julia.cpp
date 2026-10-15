#include <cstddef>
#include <cstdint>
#include <cstring>

static void put_f64_le(double value, std::uint8_t *output, std::size_t offset) {
    std::uint64_t bits; std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t euler_method_julia(const std::int64_t *input, std::size_t length,
                                            std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length != 3 || input[0] < -8 || input[0] > 8 || input[1] < 1 || input[1] > 16 || input[2] < 1 || input[2] > 4) return -1;
    const auto steps = static_cast<std::size_t>(input[1]), required = 16 * steps;
    if (!output || capacity < required) return -2;
    double states[16], times[16]; states[0] = static_cast<double>(input[0]); times[0] = 0.0;
    const double h = 1.0 / static_cast<double>(1 << input[2]);
    for (std::size_t i = 0; i + 1 < steps; ++i) {
        states[i + 1] = states[i] + h * (states[i] + times[i]);
        times[i + 1] = times[i] + h;
    }
    for (std::size_t i = 0; i < steps; ++i) { put_f64_le(states[i], output, 8 * i); put_f64_le(times[i], output, 8 * (steps + i)); }
    return static_cast<std::int64_t>(required);
}
