use std::f64::consts::PI;
#[no_mangle]
pub extern "C" fn power_factor_correction(v: *const i64, n: usize) -> f64 {
    if v.is_null() || n != 6 { return -1.0e300; }
    let (op,voltage,frequency,power,cb,eb)=unsafe{(*v,*v.add(1),*v.add(2),*v.add(3),*v.add(4),*v.add(5))};
    if (op != 0 && op != 1) || !(1..=1000).contains(&voltage) || !(1..=1000).contains(&frequency) || !(-1_000_000..=1_000_000).contains(&power) || !(-10_000..=10_000).contains(&cb) || !(-10_000..=10_000).contains(&eb) || cb == 0 || eb == 0 || (op == 1 && cb == eb) { return -1.0e300; }
    let c=cb as f64/10000.0; let e=eb as f64/10000.0; let p=power as f64;
    let dq=(p/c)*c.acos().sin()-(p/e)*e.acos().sin();
    if op == 0 { return dq/(2.0*PI*frequency as f64*(voltage as f64)*(voltage as f64)); }
    (voltage as f64)*(voltage as f64)/(2.0*PI*frequency as f64*dq)
}
