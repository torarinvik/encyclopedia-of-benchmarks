/// Selected component of single-phase complex apparent power.
#[no_mangle]
pub extern "C" fn apparent_power(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 5 { return -1.0e300; }
    let inputs = unsafe { std::slice::from_raw_parts(values, length) };
    let component = inputs[0];
    let voltage = inputs[1];
    let current = inputs[2];
    let voltage_angle = inputs[3];
    let current_angle = inputs[4];
    if (component != 0 && component != 1) || !(0..=1000).contains(&voltage) ||
        !(0..=1000).contains(&current) || !(-360..=360).contains(&voltage_angle) ||
        !(-360..=360).contains(&current_angle) { return -1.0e300; }
    let pi = 3.14159265358979323846_f64;
    let voltage_radians = (voltage_angle as f64) * (pi / 180.0);
    let current_radians = (current_angle as f64) * (pi / 180.0);
    let voltage_real = (voltage as f64) * voltage_radians.cos();
    let voltage_imag = (voltage as f64) * voltage_radians.sin();
    let current_real = (current as f64) * current_radians.cos();
    let current_imag = (current as f64) * current_radians.sin();
    let real = voltage_real * current_real - voltage_imag * current_imag;
    let imag = voltage_real * current_imag + voltage_imag * current_real;
    if component == 0 { real } else { imag }
}
