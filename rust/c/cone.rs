/// Selected volume or total surface area of a circular cone.
#[no_mangle]
pub extern "C" fn cone(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let inputs = unsafe { std::slice::from_raw_parts(values, length) };
    let operation = inputs[0];
    let radius = inputs[1];
    let height = inputs[2];
    if (operation != 0 && operation != 1) || !(0..=1000).contains(&radius) ||
        !(0..=1000).contains(&height) { return -1.0e300; }
    let pi = 3.14159265358979323846_f64;
    let radius_value = radius as f64;
    let radius_squared = radius_value * radius_value;
    let base_area = radius_squared * pi;
    if operation == 0 { return (base_area * (height as f64) * 1.0) / 3.0; }
    let height_value = height as f64;
    base_area + pi * radius_value * (radius_squared + height_value * height_value).sqrt()
}
