#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::int64_t COEFFICIENT_LIMIT = 1'000'000;

void write_f64_le(std::uint8_t* output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t quadratic_roots(const std::int64_t* values, std::size_t length,
                                         std::uint8_t* output,
                                         std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 3) return -1;
    const std::int64_t ai = values[0], bi = values[1], ci = values[2];
    if (ai == 0 || ai < -COEFFICIENT_LIMIT || ai > COEFFICIENT_LIMIT ||
        bi < -COEFFICIENT_LIMIT || bi > COEFFICIENT_LIMIT ||
        ci < -COEFFICIENT_LIMIT || ci > COEFFICIENT_LIMIT) return -1;

    const double a = static_cast<double>(ai), b = static_cast<double>(bi),
                 c = static_cast<double>(ci);
    const double discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return 0;

    if (discriminant == 0.0) {
        if (output == nullptr || output_capacity < 8) return -2;
        write_f64_le(output, 0, -b / (2.0 * a));
        return 1;
    }

    if (output == nullptr || output_capacity < 16) return -2;
    const double square_root = std::sqrt(discriminant);
    write_f64_le(output, 0, (-b + square_root) / (2.0 * a));
    write_f64_le(output, 8, (-b - square_root) / (2.0 * a));
    return 2;
}

