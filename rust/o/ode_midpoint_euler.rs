const MAX_STEPS: i64 = 8;
const OUTPUT_BYTES: usize = 16;

#[no_mangle]
pub unsafe extern "C" fn ode_midpoint_euler(input: *const i64, length: usize,
                                             output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 4 { return -1; }
    let steps = *input;
    let dt_quarters = *input.add(1);
    let u0 = *input.add(2);
    let v0 = *input.add(3);
    if !(1..=MAX_STEPS).contains(&steps) || !(1..=4).contains(&dt_quarters) ||
        !(-10..=10).contains(&u0) || !(-10..=10).contains(&v0) { return -1; }
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }

    let dt = dt_quarters as f64 / 4.0;
    let half_dt = 0.5 * dt;
    let mut u = u0 as f64;
    let mut v = v0 as f64;
    for _ in 0..steps {
        let midpoint_u = u + half_dt * v;
        let midpoint_v = v - half_dt * u;
        let next_u = u + dt * midpoint_v;
        let next_v = v - dt * midpoint_u;
        u = next_u;
        v = next_v;
    }
    std::ptr::copy_nonoverlapping(u.to_bits().to_le_bytes().as_ptr(), output, 8);
    std::ptr::copy_nonoverlapping(v.to_bits().to_le_bytes().as_ptr(), output.add(8), 8);
    OUTPUT_BYTES as i64
}
