#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 4;
constexpr std::int64_t max_temperature_mk = 1'000'000;
constexpr std::int64_t max_molar_mass_micro = 1'000'000'000;
constexpr double gas_constant = 8.31446261815324;
constexpr double pi_value = 3.14159265358979323846264338327950288;
constexpr double invalid_result = -1.0e300;
}

extern "C" double speeds_of_gas_molecules(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input_length) return invalid_result;
    const auto operation = input[0];
    const auto temperature_mk = input[1];
    const auto molar_mass_micro = input[2];
    if (length != 3 || operation < 0 || operation > 1 ||
        temperature_mk < 0 || temperature_mk > max_temperature_mk ||
        molar_mass_micro < 1 || molar_mass_micro > max_molar_mass_micro) return invalid_result;

    const double temperature = static_cast<double>(temperature_mk) / 1000.0;
    const double molar_mass = static_cast<double>(molar_mass_micro) / 1000000.0;
    if (operation == 0)
        return std::pow((8.0 * gas_constant * temperature) / (pi_value * molar_mass), 0.5);
    return std::pow((2.0 * gas_constant * temperature) / molar_mass, 0.5);
}
