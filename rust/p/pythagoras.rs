const INVALID: f64 = -1.0e300;
#[no_mangle]
pub unsafe extern "C" fn pythagoras(v: *const i64, n: usize) -> f64 {
 if v.is_null() || n != 6 { return INVALID; }
 let a=std::slice::from_raw_parts(v,n);
 if a.iter().any(|&x| x < -1_000_000 || x > 1_000_000) { return INVALID; }
 let dx=(a[3]-a[0]) as f64;let dy=(a[4]-a[1]) as f64;let dz=(a[5]-a[2]) as f64;
 (dx*dx+dy*dy+dz*dz).sqrt()
}
