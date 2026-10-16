#[no_mangle]
pub unsafe extern "C" fn federated_averaging(input: *const i64, length: usize) -> f64 {
    const INVALID: f64 = -1.0e300;
    if input.is_null() || length < 3 || length > 17 { return INVALID; }
    let values = std::slice::from_raw_parts(input, length);
    let clients = values[0];
    if !(1..=8).contains(&clients) || length != 1 + 2 * clients as usize { return INVALID; }
    let mut total = 0.0;
    for i in 0..clients as usize {
        let weight = values[1 + i];
        if !(0..=1000).contains(&weight) { return INVALID; }
        total += weight as f64;
    }
    if total <= 0.0 { return INVALID; }
    let mut result = 0.0;
    for i in 0..clients as usize {
        let value = values[1 + clients as usize + i];
        if !(-1000..=1000).contains(&value) { return INVALID; }
        let normalized = values[1 + i] as f64 / total;
        result += normalized * value as f64;
    }
    result
}
