/// Port of the pinned Go sine wrapper and its Bhaskara-style cosine formula.
#[no_mangle]
pub extern "C" fn sin_radians(radians: f64) -> f64 {
    if !(radians >= -1_000_000.0 && radians <= 1_000_000.0) {
        return -1.0;
    }
    let mut x = (3.141592653589793 / 2.0) - radians;
    let tp = 1.0 / (2.0 * 3.141592653589793);
    x *= tp;
    x -= 0.25 + (x + 0.25).floor();
    x *= 16.0 * (x.abs() - 0.5);
    x += 0.225 * x * (x.abs() - 1.0);
    x
}
