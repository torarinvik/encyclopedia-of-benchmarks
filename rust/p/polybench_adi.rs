const MAX_DIMENSION: usize = 32;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_TSTEPS: i64 = 20;

fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn polybench_adi(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 1 || input[0] as usize > MAX_DIMENSION || input[1] < 1 || input[1] > MAX_TSTEPS {
        return -1;
    }
    let n = input[0] as usize;
    let tsteps = input[1] as usize;
    let cells = n * n;
    let output_bytes = cells * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    let mut u = [0.0_f64; MAX_CELLS];
    let mut v = [0.0_f64; MAX_CELLS];
    let mut p = [0.0_f64; MAX_CELLS];
    let mut q = [0.0_f64; MAX_CELLS];
    for i in 0..n {
        for j in 0..n {
            u[i * n + j] = (i + n - j) as f64 / n as f64;
        }
    }

    let dx = 1.0 / n as f64;
    let dy = 1.0 / n as f64;
    let dt = 1.0 / tsteps as f64;
    let b1 = 2.0;
    let b2 = 1.0;
    let mul1 = b1 * dt / (dx * dx);
    let mul2 = b2 * dt / (dy * dy);
    let a = -mul1 / 2.0;
    let b = 1.0 + mul1;
    let c = a;
    let d = -mul2 / 2.0;
    let e = 1.0 + mul2;
    let f = d;

    for _ in 1..=tsteps {
        for i in 1..n.saturating_sub(1) {
            v[i] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = v[i];
            for j in 1..n.saturating_sub(1) {
                p[i * n + j] = -c / (a * p[i * n + j - 1] + b);
                q[i * n + j] = (-d * u[j * n + i - 1] + (1.0 + 2.0 * d) * u[j * n + i]
                                - f * u[j * n + i + 1] - a * q[i * n + j - 1])
                               / (a * p[i * n + j - 1] + b);
            }
            v[(n - 1) * n + i] = 1.0;
            let mut j = n - 1;
            while j > 1 {
                j -= 1;
                v[j * n + i] = p[i * n + j] * v[(j + 1) * n + i] + q[i * n + j];
            }
        }

        for i in 1..n.saturating_sub(1) {
            u[i * n] = 1.0;
            p[i * n] = 0.0;
            q[i * n] = u[i * n];
            for j in 1..n.saturating_sub(1) {
                p[i * n + j] = -f / (d * p[i * n + j - 1] + e);
                q[i * n + j] = (-a * v[(i - 1) * n + j] + (1.0 + 2.0 * a) * v[i * n + j]
                                - c * v[(i + 1) * n + j] - d * q[i * n + j - 1])
                               / (d * p[i * n + j - 1] + e);
            }
            u[i * n + n - 1] = 1.0;
            let mut j = n - 1;
            while j > 1 {
                j -= 1;
                u[i * n + j] = p[i * n + j] * u[i * n + j + 1] + q[i * n + j];
            }
        }
    }

    for index in 0..cells { write_f64_le(output, index * 8, u[index]); }
    output_bytes as i64
}
