/// Equivalent capacitance for series and parallel connections.
#[no_mangle]
pub extern "C" fn capacitor_equivalence(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(2..=33).contains(&length) { return -1.0e300; }
    let operation = unsafe { *values };
    if operation != 0 && operation != 1 { return -1.0e300; }
    let mut accumulated = 0.0;
    for index in 1..length {
        let capacitor = unsafe { *values.add(index) };
        if (operation == 0 && capacitor < 0) || (operation == 1 && capacitor < 1) || capacitor > 1000 {
            return -1.0e300;
        }
        if operation == 0 { accumulated += capacitor as f64; }
        else { accumulated += 1.0 / capacitor as f64; }
    }
    if operation == 0 { accumulated } else { 1.0 / accumulated }
}
