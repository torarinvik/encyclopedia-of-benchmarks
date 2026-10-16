use std::slice;
#[no_mangle]
pub extern "C" fn pyramid(v:*const i64,n:usize)->f64{if v.is_null()||n!=3{return -1e300}let a=unsafe{slice::from_raw_parts(v,n)};if !(0..=1).contains(&a[0])||!(1..=10_000_000).contains(&a[1])||!(1..=10_000_000).contains(&a[2]){return -1e300}let b=a[1]as f64/1000.0;let h=a[2]as f64/1000.0;let area=b.powf(2.0);if a[0]==0{return (area*h)/3.0}area+((b*4.0)/2.0)*((b/2.0).powf(2.0)+h.powf(2.0)).sqrt()}
