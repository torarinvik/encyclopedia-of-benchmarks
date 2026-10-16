#[no_mangle]
pub extern "C" fn laplacian_filter(v: *const i64, n: usize) -> f64 { if n != 9 || v.is_null() { return -1.0e300; } let a=unsafe{std::slice::from_raw_parts(v,n)}; if a.iter().any(|&x| !(0..=255).contains(&x)) { return -1.0e300; } (4*a[4]-a[1]-a[3]-a[5]-a[7]) as f64 }
