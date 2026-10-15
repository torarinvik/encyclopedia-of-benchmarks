/// Net present value with source-ordered binary64 terms.
const INVALID: f64 = -1e300;
#[no_mangle]
pub unsafe extern "C" fn npv(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 { return INVALID; }
    let values=std::slice::from_raw_parts(input,length);
    let n64=values[0];let rate_bp=values[1];
    if !(0..=64).contains(&n64) || !(0..=1000).contains(&rate_bp) || length!=n64 as usize+2 || values[2..].iter().any(|v| !(-1_000_000..=1_000_000).contains(v)) { return INVALID; }
    let rate=rate_bp as f64/10000.0;
    let mut total=0.0f64;
    for (t,&cash_flow) in values[2..].iter().enumerate() {
        let term=cash_flow as f64/(1.0+rate).powi(t as i32);
        total+=term;
    }
    total
}
