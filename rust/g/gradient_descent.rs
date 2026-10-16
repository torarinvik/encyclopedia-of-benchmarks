const INVALID: f64 = -1.0e300;
#[no_mangle]
pub extern "C" fn gradient_descent(input: *const i64, length: usize) -> f64 {
 if input.is_null() || !(5..=68).contains(&length) { return INVALID; }
 let v=unsafe { std::slice::from_raw_parts(input,length) }; let d=v[0]; let selected=v[1]; let rate=v[2]; let iterations=v[3];
 if !(1..=64).contains(&d) || selected<0 || selected>=d || length!=4+d as usize || !(1..=500000).contains(&rate) || !(0..=10000).contains(&iterations) { return INVALID; }
 let mut x=[0.0f64;64]; for i in 0..d as usize { if !(-10..=10).contains(&v[4+i]) {return INVALID;} x[i]=v[4+i] as f64; }
 let alpha=rate as f64/1_000_000.0;
 for _ in 0..iterations { let mut g=[0.0f64;64]; for i in 0..d as usize {g[i]=2.0*x[i];} for i in 0..d as usize {x[i]-=alpha*g[i];} }
 x[selected as usize]
}
