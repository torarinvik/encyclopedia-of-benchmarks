module doppler_frequency;

const double INVALID_RESULT = -1.0e300;

fn double doppler_frequency(long* values, usz length) @export("doppler_frequency") {
    if (values == null || length != 4) return INVALID_RESULT;
    long org_freq = values[0];
    long wave_vel = values[1];
    long obs_vel = values[2];
    long src_vel = values[3];
    if (org_freq < 1 || org_freq > 1000 || wave_vel < 200 || wave_vel > 1000 ||
        obs_vel < -100 || obs_vel > 100 || src_vel < -100 || src_vel > 100) return INVALID_RESULT;
    return ((double)org_freq * ((double)wave_vel + (double)obs_vel)) / ((double)wave_vel - (double)src_vel);
}
