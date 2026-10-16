#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INPUT_SCALE = 1'000'000;
constexpr std::int64_t MAX_SPEED = 1'000'000'000;
constexpr std::int64_t MAX_ANGLE = 360'000'000;
constexpr std::int64_t MIN_GRAVITY = 1'000;
constexpr std::int64_t MAX_GRAVITY = 100'000'000;
constexpr std::int64_t MAX_TIME = 1'000'000'000;
constexpr double INVALID_RESULT = -1.0e300;
constexpr double PI_VALUE = 3.14159265358979323846264338327950288;
}

extern "C" double ground_to_ground_projectile_motion(
    const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return INVALID_RESULT;
    const std::int64_t operation = values[0], speed_value = values[1];
    const std::int64_t angle_value = values[2], auxiliary_value = values[3];
    if (operation < 0 || operation > 2 || speed_value < 0 || speed_value > MAX_SPEED ||
        angle_value < -MAX_ANGLE || angle_value > MAX_ANGLE) return INVALID_RESULT;
    if (operation == 1) {
        if (auxiliary_value < 0 || auxiliary_value > MAX_TIME) return INVALID_RESULT;
    } else if (auxiliary_value < MIN_GRAVITY || auxiliary_value > MAX_GRAVITY) {
        return INVALID_RESULT;
    }

    const double speed = static_cast<double>(speed_value) / static_cast<double>(INPUT_SCALE);
    const double angle = static_cast<double>(angle_value) / static_cast<double>(INPUT_SCALE);
    const double radians = angle * (PI_VALUE / 180.0);
    const double vertical_velocity = speed * std::sin(radians);
    if (operation == 0) {
        const double gravity = static_cast<double>(auxiliary_value) / static_cast<double>(INPUT_SCALE);
        return 2.0 * vertical_velocity / gravity;
    }
    if (operation == 1) {
        const double time = static_cast<double>(auxiliary_value) / static_cast<double>(INPUT_SCALE);
        return (speed * std::cos(radians)) * time;
    }
    const double gravity = static_cast<double>(auxiliary_value) / static_cast<double>(INPUT_SCALE);
    return std::pow(vertical_velocity, 2.0) / (2.0 * gravity);
}
