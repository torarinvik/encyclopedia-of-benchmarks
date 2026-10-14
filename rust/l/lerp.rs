/// Binary64 interpolation in the classic start + t * (end - start) form.
#[no_mangle]
pub extern "C" fn lerp(start: f64, end: f64, t: f64) -> f64 {
    start + t * (end - start)
}
