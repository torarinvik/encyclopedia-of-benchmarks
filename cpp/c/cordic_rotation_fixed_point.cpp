#include <array>
#include <bit>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t OUTPUT_BYTES = 24;
constexpr std::array<std::int64_t, 15> ANGLES{
    785398163, 463647609, 244978663, 124354995, 62418810,
    31239833, 15623729, 7812341, 3906230, 1953123,
    976562, 488281, 244141, 122070, 61035,
};

std::int64_t shift_floor(std::int64_t value, unsigned shift) {
    if (shift == 0) return value;
    const std::int64_t divisor = INT64_C(1) << shift;
    if (value >= 0) return value / divisor;
    return -((-value + divisor - 1) / divisor);
}

void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    const std::uint64_t bits = std::bit_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}
}  // namespace

extern "C" std::int64_t cordic_rotation_fixed_point(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 2 || length > 3) return -1;
    if (length != 2) return -1;
    const std::int64_t angle = values[0];
    const std::int64_t stages = values[1];
    if (angle < -INT64_C(3141592653) || angle > INT64_C(3141592653) ||
        stages < 1 || stages > 16) return -1;
    if (output == nullptr || output_capacity < OUTPUT_BYTES) return -2;

    std::int64_t x = INT64_C(1000000000), y = 0, z = angle;
    std::int64_t direction = z >= 0 ? 1 : -1;
    if (direction > 0) {
        const auto old_x = x;
        x = -y;
        y = old_x;
    } else {
        const auto old_x = x;
        x = y;
        y = -old_x;
    }
    z -= direction * INT64_C(1570796327);
    for (unsigned shift = 0; shift < static_cast<unsigned>(stages - 1); ++shift) {
        direction = z >= 0 ? 1 : -1;
        const auto old_x = x;
        const auto old_y = y;
        x = old_x - direction * shift_floor(old_y, shift);
        y = old_y + direction * shift_floor(old_x, shift);
        z -= direction * ANGLES[shift];
    }

    std::array<std::uint8_t, OUTPUT_BYTES> staged{};
    constexpr double scale = 1000000000.0;
    put_f64_le(staged.data(), 0, static_cast<double>(x) / scale);
    put_f64_le(staged.data(), 8, static_cast<double>(y) / scale);
    put_f64_le(staged.data(), 16, static_cast<double>(z) / scale);
    for (std::size_t byte = 0; byte < OUTPUT_BYTES; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(OUTPUT_BYTES);
}
