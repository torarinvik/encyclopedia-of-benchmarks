/// Doppler frequency using the bounded integer-valued source contract.
export fn doppler_frequency(values: [*]const i64, length: usize) f64 {
    if (length != 4) return -1.0e300;
    const org_freq = values[0];
    const wave_vel = values[1];
    const obs_vel = values[2];
    const src_vel = values[3];
    if (org_freq < 1 or org_freq > 1000 or wave_vel < 200 or wave_vel > 1000 or
        obs_vel < -100 or obs_vel > 100 or src_vel < -100 or src_vel > 100) return -1.0e300;
    return (@as(f64, @floatFromInt(org_freq)) *
        (@as(f64, @floatFromInt(wave_vel)) + @as(f64, @floatFromInt(obs_vel)))) /
        (@as(f64, @floatFromInt(wave_vel)) - @as(f64, @floatFromInt(src_vel)));
}
