// Evaluate the six pinned full-wave rectifier helper formulas.
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::int64_t output_bytes = 48;
void store_f64_le(std::uint8_t *output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t full_wave_rectifier(const std::int64_t *values,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 5) return -1;
    const auto rf_i = values[0], rs_i = values[1], rl_i = values[2];
    const auto vm_i = values[3], im_i = values[4];
    if (rf_i < 0 || rf_i > 1'000'000 || rs_i < 0 || rs_i > 1'000'000 ||
        rl_i < 1 || rl_i > 1'000'000 || vm_i < -1'000'000 || vm_i > 1'000'000 ||
        im_i < -1'000'000 || im_i > 1'000'000) return -1;
    if (output == nullptr || output_capacity < static_cast<std::size_t>(output_bytes)) return -2;

    const double rf = static_cast<double>(rf_i), rs = static_cast<double>(rs_i);
    const double rl = static_cast<double>(rl_i), vm = static_cast<double>(vm_i);
    const double im = static_cast<double>(im_i);
    store_f64_le(output, 0, vm / (rf + rs + rl));
    store_f64_le(output, 8, 2.0 * im * 0.318);
    store_f64_le(output, 16, 2.0 * 0.318 * vm);
    store_f64_le(output, 24, vm / rl);
    store_f64_le(output, 32, im * 0.707);
    store_f64_le(output, 40, vm * 0.707);
    return output_bytes;
}
