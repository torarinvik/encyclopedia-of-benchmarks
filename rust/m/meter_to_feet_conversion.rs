#[no_mangle]
pub extern "C" fn meter_to_feet_conversion(v: *const i64, n: usize) -> f64 {
    if v.is_null() || n != 2 { return -1.0e300; }
    let op=unsafe{*v}; let units=unsafe{*v.add(1)};
    if (op != 0 && op != 1) || !(-1_000_000_000..=1_000_000_000).contains(&units) { return -1.0e300; }
    let value=units as f64/1000.0;
    if op == 0 { return value*0.3048; }
    value/0.3048
}
