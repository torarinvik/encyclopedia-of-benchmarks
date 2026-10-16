#[no_mangle]
pub extern "C" fn standard_score(value: f64, mean: f64, std_dev: f64) -> f64 {
    let valid_std_dev = (-1_000_000.0..=-0.000001).contains(&std_dev)
        || (0.000001..=1_000_000.0).contains(&std_dev);
    if !(-1_000_000.0..=1_000_000.0).contains(&value)
        || !(-1_000_000.0..=1_000_000.0).contains(&mean)
        || !valid_std_dev
    {
        return -1e300;
    }
    (value - mean) / std_dev
}
