const MAX_N: usize = 10_000;
const OUTPUT_COUNT: usize = 9;

#[no_mangle]
pub unsafe extern "C" fn partialsums(input: *const f64, length: usize,
                                       output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n_value = *input;
    if !n_value.is_finite() || n_value.fract() != 0.0 || n_value < 1.0 || n_value > MAX_N as f64 {
        return -1;
    }
    let n = n_value as usize;
    let mut geometric = 0.0;
    let mut inverse_sqrt = 0.0;
    let mut flint = 0.0;
    let mut cookson = 0.0;
    let mut telescoping = [0.0; 2];
    let mut harmonic = [0.0; 2];
    let mut zeta = [0.0; 2];
    let mut alternating = [0.0; 2];
    let mut gregory = [0.0; 2];
    let mut term = 1.0;
    let vector_limit = n + (n & 1);
    for k in 1..=vector_limit {
        let kd = k as f64;
        let lane = (k - 1) & 1;
        if k <= n {
            let k3 = kd * kd * kd;
            let s = kd.sin();
            let c = kd.cos();
            geometric += term;
            term *= 2.0 / 3.0;
            inverse_sqrt += 1.0 / kd.sqrt();
            flint += 1.0 / (k3 * s * s);
            cookson += 1.0 / (k3 * c * c);
        }
        telescoping[lane] += 1.0 / (kd * (kd + 1.0));
        harmonic[lane] += 1.0 / kd;
        zeta[lane] += 1.0 / (kd * kd);
        let sign = if lane == 0 { 1.0 } else { -1.0 };
        alternating[lane] += sign / kd;
        gregory[lane] += sign / (2.0 * kd - 1.0);
    }
    if output.is_null() || capacity < OUTPUT_COUNT { return -2; }
    let values = [
        geometric,
        inverse_sqrt,
        telescoping[0] + telescoping[1],
        flint,
        cookson,
        harmonic[0] + harmonic[1],
        zeta[0] + zeta[1],
        alternating[0] + alternating[1],
        gregory[0] + gregory[1],
    ];
    std::ptr::copy_nonoverlapping(values.as_ptr(), output, OUTPUT_COUNT);
    OUTPUT_COUNT as i64
}
