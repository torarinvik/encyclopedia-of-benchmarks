/// Bounded Gauss-Legendre quadrature using the pinned Fortran tables.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn gaussian_legendre(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 7 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(values, length);
    if !(1..=5).contains(&values[0]) || !(-5000..=5000).contains(&values[1])
        || !(-5000..=5000).contains(&values[2]) { return INVALID_RESULT; }
    if values[3..].iter().any(|&value| !(-10000..=10000).contains(&value)) { return INVALID_RESULT; }

    let (nodes, weights): ([f64; 5], [f64; 5]) = match values[0] {
        1 => ([0.0; 5], [2.0, 0.0, 0.0, 0.0, 0.0]),
        2 => ([-0.5773502692, 0.5773502692, 0.0, 0.0, 0.0], [1.0, 1.0, 0.0, 0.0, 0.0]),
        3 => ([-0.7745966692, 0.0, 0.7745966692, 0.0, 0.0], [0.5555555556, 0.8888888889, 0.5555555556, 0.0, 0.0]),
        4 => ([-0.8611363116, -0.3399810436, 0.3399810436, 0.8611363116, 0.0], [0.3478548451, 0.6521451549, 0.6521451549, 0.3478548451, 0.0]),
        _ => ([-0.9061798459, -0.5384693101, 0.0, 0.5384693101, 0.9061798459], [0.2369268851, 0.4786286705, 0.5688888889, 0.4786286705, 0.2369268851]),
    };
    let order = values[0] as usize;
    let a = values[1] as f64 / 1000.0;
    let b = values[2] as f64 / 1000.0;
    let c0 = values[3] as f64 / 1000.0;
    let c1 = values[4] as f64 / 1000.0;
    let c2 = values[5] as f64 / 1000.0;
    let c3 = values[6] as f64 / 1000.0;
    let mut weighted_sum = 0.0;
    for index in 0..order {
        let x = (b + a) / 2.0 + (b - a) * nodes[index] / 2.0;
        let x2 = x * x;
        let x3 = x2 * x;
        let function_value = c0 + c1 * x + c2 * x2 + c3 * x3;
        weighted_sum += weights[index] * function_value;
    }
    weighted_sum * (b - a) / 2.0
}
