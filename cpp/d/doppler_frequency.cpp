// Doppler frequency using the bounded integer-valued source contract.
#include <cstddef>
#include <cstdint>

constexpr double INVALID_RESULT = -1.0e300;

extern "C" double doppler_frequency(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return INVALID_RESULT;
    const auto org_freq = values[0];
    const auto wave_vel = values[1];
    const auto obs_vel = values[2];
    const auto src_vel = values[3];
    if (org_freq < 1 || org_freq > 1000 || wave_vel < 200 || wave_vel > 1000 ||
        obs_vel < -100 || obs_vel > 100 || src_vel < -100 || src_vel > 100) return INVALID_RESULT;
    return (static_cast<double>(org_freq) * (static_cast<double>(wave_vel) + static_cast<double>(obs_vel))) /
        (static_cast<double>(wave_vel) - static_cast<double>(src_vel));
}
