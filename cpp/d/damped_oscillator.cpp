#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
void put_f64_le(std::uint8_t* output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t damped_oscillator(const std::int64_t* input, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 5) return -1;
    if (input[0] < 1 || input[0] > 1024 || input[1] < 0 || input[1] > 1024 ||
        input[2] < -1024 || input[2] > 1024 || input[3] < -1024 || input[3] > 1024 ||
        input[4] < 1 || input[4] > 1024) return -1;
    if (output == nullptr || capacity < 16) return -2;
    const double omega0 = static_cast<double>(input[0]) / 1024.0;
    const double gamma = static_cast<double>(input[1]) / 1024.0;
    const double x = static_cast<double>(input[2]) / 1024.0;
    const double v = static_cast<double>(input[3]) / 1024.0;
    const double dt = static_cast<double>(input[4]) / 1024.0;
    const double acceleration = -2.0 * gamma * v - omega0 * omega0 * x;
    const double x_next = x + dt * v;
    const double v_next = v + dt * acceleration;
    put_f64_le(output, 0, x_next);
    put_f64_le(output, 8, v_next);
    return 16;
}
