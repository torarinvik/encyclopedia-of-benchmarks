/// Series and parallel resistor equivalents.
#[no_mangle]
pub extern "C" fn resistor_equivalence(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(2..=33).contains(&length) { return -1.0e300; }
    let operation = unsafe { *values };
    if operation != 0 && operation != 1 { return -1.0e300; }
    let mut accumulated = 0.0;
    for index in 1..length {
        let resistor = unsafe { *values.add(index) };
        if (operation == 0 && resistor < 1) || (operation == 1 && resistor < 0) || resistor > 1000 {
            return -1.0e300;
        }
        if operation == 0 { accumulated += 1.0 / resistor as f64; }
        else { accumulated += resistor as f64; }
    }
    if operation == 0 { return 1.0 / accumulated; }
    accumulated
}
