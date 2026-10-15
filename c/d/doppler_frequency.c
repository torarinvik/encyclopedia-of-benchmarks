/* Doppler frequency using the bounded integer-valued source contract. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double doppler_frequency(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t org_freq = values[0];
    const int64_t wave_vel = values[1];
    const int64_t obs_vel = values[2];
    const int64_t src_vel = values[3];
    if (org_freq < 1 || org_freq > 1000 || wave_vel < 200 || wave_vel > 1000 ||
        obs_vel < -100 || obs_vel > 100 || src_vel < -100 || src_vel > 100) return INVALID_RESULT;
    return ((double)org_freq * ((double)wave_vel + (double)obs_vel)) / ((double)wave_vel - (double)src_vel);
}
