/// Return radius for component 0 and the atan2 angle for component 1.
#[no_mangle]
pub extern "C" fn cartesian_to_polar(x: f64, y: f64, component: f64) -> f64 {
    if x.is_nan() || y.is_nan() || (component != 0.0 && component != 1.0)
        || !(-1_000_000.0..=1_000_000.0).contains(&x)
        || !(-1_000_000.0..=1_000_000.0).contains(&y)
    {
        return -1.0e300;
    }
    if component == 0.0 { return (x * x + y * y).sqrt(); }
    if x == 0.0 && y == 0.0 { return 0.0; }
    y.atan2(x)
}
