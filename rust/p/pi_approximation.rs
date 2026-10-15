#[no_mangle]
pub unsafe extern "C" fn pi_approximation(points: *const f64, point_count: usize) -> f64 {
    let mut inside = 0u64;
    for index in 0..point_count {
        let x = *points.add(2 * index);
        let y = *points.add(2 * index + 1);
        if x * x + y * y <= 1.0 { inside += 1; }
    }
    4.0 * inside as f64 / point_count as f64
}
