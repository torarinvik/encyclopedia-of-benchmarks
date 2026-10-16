#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr double coulombs_constant = 8.9875517923e9;
constexpr std::int64_t max_charge_microcoulombs = 1'000'000;
constexpr std::int64_t max_distance_millimeters = 1'000'000;
}

extern "C" double coulombs_law(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return invalid_result;
    const auto charge1_value = values[0];
    const auto charge2_value = values[1];
    const auto distance_value = values[2];
    if (charge1_value == 0 || charge2_value == 0 ||
        charge1_value < -max_charge_microcoulombs || charge1_value > max_charge_microcoulombs ||
        charge2_value < -max_charge_microcoulombs || charge2_value > max_charge_microcoulombs ||
        distance_value < 1 || distance_value > max_distance_millimeters) return invalid_result;

    const double charge1 = static_cast<double>(charge1_value) / 1'000'000.0;
    const double charge2 = static_cast<double>(charge2_value) / 1'000'000.0;
    const double distance = static_cast<double>(distance_value) / 1'000.0;
    double charge_product = charge1 * charge2;
    if (charge_product < 0.0) charge_product = -charge_product;
    return coulombs_constant * charge_product / (distance * distance);
}
