#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::int64_t max_steps = 8;
constexpr std::int64_t output_bytes = 16;

void put_f64_le(std::uint8_t *output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t ode_midpoint_euler(const std::int64_t *input,
                                            std::size_t length,
                                            std::uint8_t *output,
                                            std::size_t capacity) noexcept {
    if (input == nullptr || length != 4) return -1;
    const std::int64_t steps = input[0];
    const std::int64_t dt_quarters = input[1];
    const std::int64_t u0 = input[2];
    const std::int64_t v0 = input[3];
    if (steps < 1 || steps > max_steps || dt_quarters < 1 || dt_quarters > 4 ||
        u0 < -10 || u0 > 10 || v0 < -10 || v0 > 10) return -1;
    if (output == nullptr || capacity < static_cast<std::size_t>(output_bytes)) return -2;

    const double dt = static_cast<double>(dt_quarters) / 4.0;
    const double half_dt = 0.5 * dt;
    double u = static_cast<double>(u0);
    double v = static_cast<double>(v0);
    for (std::int64_t step = 0; step < steps; ++step) {
        const double midpoint_u = u + half_dt * v;
        const double midpoint_v = v - half_dt * u;
        const double next_u = u + dt * midpoint_v;
        const double next_v = v - dt * midpoint_u;
        u = next_u;
        v = next_v;
    }
    put_f64_le(output, 0, u);
    put_f64_le(output, 8, v);
    return output_bytes;
}
