#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t kMaxParticles = 32;
constexpr std::size_t kMaxInputLength = 2 + 6 * kMaxParticles;
constexpr double kPi = 3.14159265358979323846264338327950288;

void store_f64_le(std::uint8_t* output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t fluidanimate_sph(const std::int64_t* input, std::size_t length,
                                          std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > kMaxInputLength) return -1;
    const auto count_value = input[0], rpm_milli = input[1];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(kMaxParticles)
            || rpm_milli < 500 || rpm_milli > 5000) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + 6 * count) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        const auto base = 2 + 6 * i;
        for (std::size_t axis = 0; axis < 3; ++axis)
            if (input[base + axis] < -10000 || input[base + axis] > 10000) return -1;
        for (std::size_t axis = 3; axis < 6; ++axis)
            if (input[base + axis] < -5000 || input[base + axis] > 5000) return -1;
    }
    const auto output_bytes = 40 * count;
    if (!output || capacity < output_bytes) return -2;

    using Vec3 = std::array<double, 3>;
    std::array<Vec3, kMaxParticles> position{}, velocity{}, acceleration{};
    std::array<double, kMaxParticles> density{};
    const double rpm = static_cast<double>(rpm_milli) / 1000.0;
    const double h = 1.695 / rpm, h2 = h * h;
    const double mass = 1000.0 / (rpm * rpm * rpm);
    const double density_coeff = mass * (315.0 / (64.0 * kPi * std::pow(h, 9.0)));
    const double pressure_coeff = 3.0 * (15.0 / (kPi * std::pow(h, 6.0))) * 1.5 * mass;
    const double viscosity_coeff = 0.4 * (45.0 / (kPi * std::pow(h, 6.0))) * mass;

    for (std::size_t i = 0; i < count; ++i) {
        const auto base = 2 + 6 * i;
        for (std::size_t axis = 0; axis < 3; ++axis) {
            position[i][axis] = static_cast<double>(input[base + axis]) / 1000.0;
            velocity[i][axis] = static_cast<double>(input[base + 3 + axis]) / 1000.0;
            acceleration[i][axis] = axis == 1 ? -9.8 : 0.0;
        }
        density[i] = density_coeff * h2 * h2 * h2;
    }
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t j = i + 1; j < count; ++j) {
            const double dx = position[i][0] - position[j][0];
            const double dy = position[i][1] - position[j][1];
            const double dz = position[i][2] - position[j][2];
            const double r2 = dx * dx + dy * dy + dz * dz;
            if (r2 < h2) {
                const double term = density_coeff * std::pow(h2 - r2, 3.0);
                density[i] += term;
                density[j] += term;
            }
        }
    }
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t j = i + 1; j < count; ++j) {
            const Vec3 disp{position[i][0] - position[j][0], position[i][1] - position[j][1],
                            position[i][2] - position[j][2]};
            const double r2 = disp[0] * disp[0] + disp[1] * disp[1] + disp[2] * disp[2];
            if (r2 >= h2) continue;
            const double distance = std::sqrt(std::max(r2, 1e-12));
            const double hmr = h - distance;
            const double rho_product = density[i] * density[j];
            const double pressure_scale = pressure_coeff * (hmr * hmr / distance)
                * (density[i] + density[j] - 2000.0) / rho_product;
            const double viscosity_scale = viscosity_coeff * hmr / rho_product;
            for (std::size_t axis = 0; axis < 3; ++axis) {
                const double force = disp[axis] * pressure_scale
                    + (velocity[j][axis] - velocity[i][axis]) * viscosity_scale;
                acceleration[i][axis] += force;
                acceleration[j][axis] -= force;
            }
        }
    }
    for (std::size_t i = 0; i < count; ++i) {
        const double fields[5] = {density[i], 3.0 * (density[i] - 1000.0),
            acceleration[i][0], acceleration[i][1], acceleration[i][2]};
        for (std::size_t field = 0; field < 5; ++field)
            store_f64_le(output, 8 * (5 * i + field), fields[field]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
