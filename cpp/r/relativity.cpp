#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double speed_of_light = 299792458.0;
constexpr std::int64_t speed_of_light_milli = 299'792'458'000;
constexpr std::int64_t max_length_time_milli = 1'000'000;
constexpr std::size_t max_input_length = 4;
constexpr double invalid_result = -1.0e300;

double lorentz_gamma(double velocity) noexcept {
    return 1.0 / std::sqrt(1.0 - velocity * velocity / (speed_of_light * speed_of_light));
}
}

extern "C" double relativity(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input_length) return invalid_result;
    const auto operation = input[0];
    const auto arg1_milli = input[1];
    const auto arg2_milli = input[2];
    if (length != 3) return invalid_result;

    if (operation == 0) {
        if (arg2_milli != 0 || arg1_milli <= -speed_of_light_milli ||
            arg1_milli >= speed_of_light_milli) return invalid_result;
        return lorentz_gamma(static_cast<double>(arg1_milli) / 1000.0);
    }
    if (operation == 1 || operation == 2) {
        if (arg1_milli < 0 || arg1_milli > max_length_time_milli ||
            arg2_milli <= -speed_of_light_milli || arg2_milli >= speed_of_light_milli) return invalid_result;
        const double quantity = static_cast<double>(arg1_milli) / 1000.0;
        const double velocity = static_cast<double>(arg2_milli) / 1000.0;
        const double gamma = lorentz_gamma(velocity);
        return operation == 1 ? quantity / gamma : quantity * gamma;
    }
    if (operation == 3) {
        if (arg1_milli < -speed_of_light_milli || arg1_milli > speed_of_light_milli ||
            arg2_milli <= -speed_of_light_milli || arg2_milli >= speed_of_light_milli) return invalid_result;
        const double velocity_one = static_cast<double>(arg1_milli) / 1000.0;
        const double frame_velocity = static_cast<double>(arg2_milli) / 1000.0;
        return (velocity_one - frame_velocity) /
               (1.0 - velocity_one * frame_velocity / (speed_of_light * speed_of_light));
    }
    return invalid_result;
}
