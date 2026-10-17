#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t scale = 1'000'000;
constexpr std::int64_t max_abs_temperature_micro = 1'000'000'000'000;
constexpr double invalid_result = -1.0e300;
constexpr std::size_t max_input_length = 3;
}

extern "C" double temperature_conversions(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2 || length > max_input_length) return invalid_result;
    const std::int64_t operation = values[0], micro = values[1];
    if (micro < -max_abs_temperature_micro || micro > max_abs_temperature_micro) return invalid_result;
    switch (operation) {
        case 0:
            if (micro % 5'000'000 != 0) return invalid_result;
            return static_cast<double>(9 * (micro / 5'000'000) + 32);
        case 1:
            if ((micro - 32'000'000) % 9'000'000 != 0) return invalid_result;
            return static_cast<double>(5 * ((micro - 32'000'000) / 9'000'000));
        case 2:
            if (micro % scale != 0) return invalid_result;
            return static_cast<double>(micro / scale) + 273.15;
        case 3:
            if ((micro - 273'150'000) % scale != 0) return invalid_result;
            return static_cast<double>((micro - 273'150'000) / scale);
        case 4:
            if ((micro - 273'150'000) % 5'000'000 != 0) return invalid_result;
            return static_cast<double>(9 * ((micro - 273'150'000) / 5'000'000) + 32);
        default: return invalid_result;
    }
}
