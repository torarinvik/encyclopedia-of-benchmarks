#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t speed_of_light = 299792458;
constexpr double invalid_result = -1.0e300;
}

extern "C" double relativistic_velocity_summation(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return invalid_result;
    const std::int64_t object_velocity = values[0];
    const std::int64_t frame_velocity = values[1];
    if (object_velocity < -speed_of_light || object_velocity > speed_of_light ||
        frame_velocity < -(speed_of_light - 1) || frame_velocity > speed_of_light - 1)
        return invalid_result;
    const std::int64_t numerator = object_velocity + frame_velocity;
    const double denominator = 1.0 + static_cast<double>(object_velocity * frame_velocity) /
        static_cast<double>(speed_of_light * speed_of_light);
    return static_cast<double>(numerator) / denominator;
}
