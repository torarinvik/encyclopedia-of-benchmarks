#[no_mangle]
pub unsafe extern "C" fn circular_orbit_velocity(v: *const f64, n: usize, output: *mut f64, capacity: usize) -> i64 {
    if v.is_null() || n!=2 { return -1; }
    let values=std::slice::from_raw_parts(v,2);
    let (mass,radius)=(values[0],values[1]);
    if !mass.is_finite() || !radius.is_finite() || mass<1.0e-12 || mass>1.0e25 || radius<1.0e-12 || radius>1.0e12 { return -1; }
    if output.is_null() || capacity<1 { return -2; }
    *output=(6.67430e-11*mass/radius).sqrt();
    1
}
