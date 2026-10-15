#include <cstddef>
#include <cstdint>
#include <cstring>

static void put_f64_le(double value, std::uint8_t *output, std::size_t offset) {
    std::uint64_t bits; std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t euler_method(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length != 4 || input[0] < -8 || input[0] > 8 || input[1] < -8 || input[1] > 8 ||
        input[2] < 1 || input[2] > 4 || input[3] < 1 || input[3] > 16) return -1;
    const auto steps = input[3]; const auto required = 8 * (static_cast<std::size_t>(steps) + 1);
    if (!output || capacity < required) return -2;
    const double h = 1.0 / static_cast<double>(1 << input[2]);
    double x = static_cast<double>(input[0]), y = static_cast<double>(input[1]);
    put_f64_le(y, output, 0);
    for (std::int64_t step = 0; step < steps; ++step) {
        y = y + h * (x + y);
        x += h;
        put_f64_le(y, output, 8 * (static_cast<std::size_t>(step) + 1));
    }
    return static_cast<std::int64_t>(required);
}
