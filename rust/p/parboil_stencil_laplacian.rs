#[no_mangle]
pub unsafe extern "C" fn parboil_stencil_laplacian(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=129).contains(&length) {
        return -1;
    }
    let nxv = *input;
    let nyv = *input.add(1);
    let nzv = *input.add(2);
    let stepsv = *input.add(3);
    let header = [nxv, nyv, nzv, stepsv];
    if header.iter().any(|value| !value.is_finite() || value.fract() != 0.0)
        || !(3.0..=5.0).contains(&nxv)
        || !(3.0..=5.0).contains(&nyv)
        || !(3.0..=5.0).contains(&nzv)
        || !(1.0..=4.0).contains(&stepsv)
    {
        return -1;
    }
    let nx = nxv as usize;
    let ny = nyv as usize;
    let nz = nzv as usize;
    let steps = stepsv as usize;
    let cells = nx * ny * nz;
    if length != 4 + cells {
        return -1;
    }
    let mut a = [0.0f32; 125];
    let mut b = [0.0f32; 125];
    let mut staged = [0.0f64; 125];
    for q in 0..cells {
        let value = *input.add(4 + q);
        if !value.is_finite() || !(-8.0..=8.0).contains(&value) {
            return -1;
        }
        a[q] = value as f32;
        b[q] = a[q];
    }
    if output.is_null() || capacity < cells {
        return -2;
    }
    let c0 = 1.0f32 / 6.0f32;
    let c1 = (1.0f32 / 6.0f32) / 6.0f32;
    for _ in 0..steps {
        for i in 1..nx - 1 {
            for j in 1..ny - 1 {
                for k in 1..nz - 1 {
                    let q = i + nx * (j + ny * k);
                    let mut sum = a[q + nx * ny] + a[q - nx * ny];
                    sum = sum + a[q + nx];
                    sum = sum + a[q - nx];
                    sum = sum + a[q + 1];
                    sum = sum + a[q - 1];
                    let neighbor_term = sum * c1;
                    let center_term = a[q] * c0;
                    b[q] = neighbor_term - center_term;
                }
            }
        }
        for q in 0..cells {
            let temp = a[q];
            a[q] = b[q];
            b[q] = temp;
        }
    }
    for q in 0..cells {
        staged[q] = a[q] as f64;
    }
    for q in 0..cells {
        *output.add(q) = staged[q];
    }
    cells as i64
}
