#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; constexpr std::int64_t max_density_ppm = 1000000; }

extern "C" double hubble_parameter(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 5) return invalid_result;
    const auto h0_x10 = values[0], radiation_ppm = values[1], matter_ppm = values[2], dark_energy_ppm = values[3], redshift_milli = values[4];
    if (h0_x10 < -2000 || h0_x10 > 2000 || radiation_ppm < 0 || radiation_ppm > max_density_ppm ||
        matter_ppm < 0 || matter_ppm > max_density_ppm || dark_energy_ppm < 0 || dark_energy_ppm > max_density_ppm ||
        radiation_ppm + matter_ppm + dark_energy_ppm > max_density_ppm || redshift_milli < 0 || redshift_milli > 10000) return invalid_result;
    const double hubble_constant = static_cast<double>(h0_x10) / 10.0;
    const double radiation_density = static_cast<double>(radiation_ppm) / 1000000.0;
    const double matter_density = static_cast<double>(matter_ppm) / 1000000.0;
    const double dark_energy = static_cast<double>(dark_energy_ppm) / 1000000.0;
    const double redshift = static_cast<double>(redshift_milli) / 1000.0;
    const double curvature = 1.0 - (matter_density + radiation_density + dark_energy);
    const double z1 = redshift + 1.0;
    const double e2 = radiation_density * std::pow(z1, 4.0) + matter_density * std::pow(z1, 3.0) + curvature * std::pow(z1, 2.0) + dark_energy;
    return hubble_constant * std::pow(e2, 1.0 / 2.0);
}
