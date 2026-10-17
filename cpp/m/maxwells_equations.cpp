#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1e300;
constexpr std::int64_t max_physical = INT64_C(1000000000000000);
constexpr std::int64_t max_flux_rate = INT64_C(1000000000000000000);
constexpr std::int64_t min_constant = INT64_C(1000000);
constexpr std::int64_t max_constant = INT64_C(1000000000000000);
constexpr double physical_scale = 1e12;
constexpr double constant_scale = 1e18;
constexpr double pi = 3.14159265358979323846264338327950288;
constexpr double epsilon_default = 8.8541878128e-12;
constexpr double mu_default = 4.0 * pi * 1e-7;
bool in_range(std::int64_t value, std::int64_t limit) { return value >= -limit && value <= limit; }
bool decode_constant(std::int64_t raw, double fallback, double& value) {
    if (raw == 0) { value = fallback; return true; }
    if (raw < min_constant || raw > max_constant) return false;
    value = static_cast<double>(raw) / constant_scale;
    return true;
}
double law_result(double actual, double expected) {
    const double tolerance = expected != 0.0 ? 0.01 * std::fabs(expected) : 1e-10;
    return std::fabs(actual - expected) <= tolerance ? 1.0 : 0.0;
}
}

extern "C" double maxwells_equations(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 7) return invalid_result;
    const auto operation = input[0];
    if (operation == 0) {
        if (length != 5) return invalid_result;
        const auto field = input[1], area = input[2], charge = input[3], epsilon_raw = input[4];
        if (!in_range(field, max_physical) || area < 0 || area > max_physical || !in_range(charge, max_physical)) return invalid_result;
        double epsilon;
        if (!decode_constant(epsilon_raw, epsilon_default, epsilon)) return invalid_result;
        const double electric_flux = (static_cast<double>(field) / physical_scale) * (static_cast<double>(area) / physical_scale);
        const double expected_flux = (static_cast<double>(charge) / physical_scale) / epsilon;
        return law_result(electric_flux, expected_flux);
    }
    if (operation == 1) {
        if (length != 3 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical)) return invalid_result;
        const double circulation = static_cast<double>(input[1]) / physical_scale;
        const double expected = -(static_cast<double>(input[2]) / physical_scale);
        return law_result(circulation, expected);
    }
    if (operation == 2) {
        if (length != 6 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical) || !in_range(input[3], max_flux_rate)) return invalid_result;
        double mu, epsilon;
        if (!decode_constant(input[4], mu_default, mu) || !decode_constant(input[5], epsilon_default, epsilon)) return invalid_result;
        const double displacement_current = epsilon * (static_cast<double>(input[3]) / 1e6);
        const double total_current = (static_cast<double>(input[2]) / physical_scale) + displacement_current;
        const double expected = mu * total_current;
        return law_result(static_cast<double>(input[1]) / physical_scale, expected);
    }
    if (operation == 3 || operation == 4) {
        if (length != 3) return invalid_result;
        double mu, epsilon;
        if (!decode_constant(input[1], mu_default, mu) || !decode_constant(input[2], epsilon_default, epsilon)) return invalid_result;
        if (operation == 3) return 1.0 / std::sqrt(mu * epsilon);
        return std::sqrt(mu / epsilon);
    }
    if (operation == 5) {
        if (length != 4 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical)) return invalid_result;
        double mu;
        if (!decode_constant(input[3], mu_default, mu)) return invalid_result;
        return ((static_cast<double>(input[1]) / physical_scale) * (static_cast<double>(input[2]) / physical_scale)) / mu;
    }
    if (operation == 6) {
        if (length != 5 || !in_range(input[1], max_physical) || !in_range(input[2], max_physical)) return invalid_result;
        double epsilon, mu;
        if (!decode_constant(input[3], epsilon_default, epsilon) || !decode_constant(input[4], mu_default, mu)) return invalid_result;
        const double electric_energy = 0.5 * epsilon * std::pow(static_cast<double>(input[1]) / physical_scale, 2.0);
        const double magnetic_energy = 0.5 * std::pow(static_cast<double>(input[2]) / physical_scale, 2.0) / mu;
        return electric_energy + magnetic_energy;
    }
    return invalid_result;
}
