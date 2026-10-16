export fn standard_score(value: f64, mean: f64, std_dev: f64) f64 {
    const valid_std_dev =
        (std_dev >= -1_000_000.0 and std_dev <= -0.000001) or
        (std_dev >= 0.000001 and std_dev <= 1_000_000.0);
    if (!(value >= -1_000_000.0 and value <= 1_000_000.0) or
        !(mean >= -1_000_000.0 and mean <= 1_000_000.0) or !valid_std_dev) return -1e300;
    return (value - mean) / std_dev;
}
