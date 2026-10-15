/// Magnetic flux rounded to one decimal place.
#[no_mangle]
pub extern "C" fn magnetic_flux(values: *const i64, length: usize) -> f64 {
    const PI_VALUE: f64 = 3.14159265358979323846;
    if values.is_null() || length != 3 { return -1.0e300; }
    let magnetic_field = unsafe { *values };
    let area = unsafe { *values.add(1) };
    let angle = unsafe { *values.add(2) };
    if !(0..=10_000).contains(&magnetic_field) || !(0..=10_000).contains(&area) ||
        !(angle == 0 || angle == 60 || angle == 90 || angle == 120 || angle == 180) {
        return -1.0e300;
    }
    let radians = angle as f64 * (PI_VALUE / 180.0);
    let flux = magnetic_field as f64 * area as f64 * radians.cos();
    (flux * 10.0).round() / 10.0
}
