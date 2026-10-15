#[no_mangle]
pub extern "C" fn kelvin_to_celsius(temperature_in_k: f64) -> f64 {
    if !(temperature_in_k >= 0.0 && temperature_in_k <= 1_000_000.0) {
        return -1.0;
    }
    let absolute_zero_in_c = -273.15;
    temperature_in_k + absolute_zero_in_c
}
