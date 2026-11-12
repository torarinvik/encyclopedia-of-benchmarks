use std::slice;

const MAX_POINTS: usize = 32;
const MAX_AXIS: i64 = 4;
const MAX_SWEEPS: i64 = 8;
const MAX_MICRO: i64 = 1_000_000_000;
const SCALE: f64 = 1_000_000.0;

fn solve5(d: &[f64; 25], rhs: [f64; 5]) -> Option<[f64; 5]> {
    let mut a = *d;
    let mut b = rhs;
    for pivot in 0..5 {
        let divisor = a[pivot * 5 + pivot];
        if !(divisor > 0.0) || !divisor.is_finite() { return None; }
        for row in pivot + 1..5 {
            let factor = a[row * 5 + pivot] / divisor;
            for column in pivot + 1..5 {
                a[row * 5 + column] -= factor * a[pivot * 5 + column];
            }
            b[row] -= factor * b[pivot];
        }
    }
    let mut x = [0.0; 5];
    for row in (0..5).rev() {
        let mut tail = 0.0;
        for column in row + 1..5 { tail += a[row * 5 + column] * x[column]; }
        x[row] = (b[row] - tail) / a[row * 5 + row];
    }
    Some(x)
}

fn apply(nx: usize, ny: usize, nz: usize, d: &[f64; 25], c: &[f64; 3],
         x: &[f64; MAX_POINTS * 5], out: &mut [f64; MAX_POINTS * 5]) {
    let points = nx * ny * nz;
    let nxy = nx * ny;
    for point in 0..points {
        let ix = point % nx;
        let iy = (point / nx) % ny;
        let iz = point / nxy;
        let previous = [if ix > 0 { Some(point - 1) } else { None },
                        if iy > 0 { Some(point - nx) } else { None },
                        if iz > 0 { Some(point - nxy) } else { None }];
        let following = [if ix + 1 < nx { Some(point + 1) } else { None },
                         if iy + 1 < ny { Some(point + nx) } else { None },
                         if iz + 1 < nz { Some(point + nxy) } else { None }];
        for row in 0..5 {
            let mut value = 0.0;
            for column in 0..5 { value += d[row * 5 + column] * x[point * 5 + column]; }
            for axis in 0..3 {
                if let Some(other) = previous[axis] { value += c[axis] * x[other * 5 + row]; }
                if let Some(other) = following[axis] { value += c[axis] * x[other * 5 + row]; }
            }
            out[point * 5 + row] = value;
        }
    }
}

fn valid(v: &[i64]) -> Option<(usize, usize, usize, usize)> {
    if v.len() < 42 || v.len() > 32 + 10 * MAX_POINTS
        || !(1..=MAX_AXIS).contains(&v[0]) || !(1..=MAX_AXIS).contains(&v[1])
        || !(1..=MAX_AXIS).contains(&v[2]) || !(1..=MAX_SWEEPS).contains(&v[3]) { return None; }
    let (nx, ny, nz) = (v[0] as usize, v[1] as usize, v[2] as usize);
    let points = nx * ny * nz;
    if points > MAX_POINTS || v.len() != 32 + 10 * points
        || v[4..].iter().any(|&x| x < -MAX_MICRO || x > MAX_MICRO) { return None; }
    for row in 0..5 {
        let diagonal = v[4 + row * 5 + row];
        let mut off_sum = 0_i64;
        for column in 0..5 {
            let entry = v[4 + row * 5 + column];
            if entry != v[4 + column * 5 + row] { return None; }
            if row != column { off_sum += entry.abs(); }
        }
        for (axis, extent) in [nx, ny, nz].iter().enumerate() {
            if *extent > 1 { off_sum += 2 * v[29 + axis].abs(); }
        }
        if diagonal <= 0 || diagonal <= off_sum { return None; }
    }
    Some((nx, ny, nz, v[3] as usize))
}

unsafe fn write_le(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() { output.add(offset + index).write(*byte); }
}

unsafe fn run(v: &[i64], nx: usize, ny: usize, nz: usize, sweeps: usize,
              output: *mut u8) -> Option<usize> {
    let points = nx * ny * nz;
    let count = points * 5;
    let mut d = [0.0; 25];
    let mut c = [0.0; 3];
    for index in 0..25 { d[index] = v[4 + index] as f64 / SCALE; }
    for axis in 0..3 { c[axis] = v[29 + axis] as f64 / SCALE; }
    let mut x = [0.0; MAX_POINTS * 5];
    let mut rhs = [0.0; MAX_POINTS * 5];
    let mut applied = [0.0; MAX_POINTS * 5];
    let mut residual = [0.0; MAX_POINTS * 5];
    let mut forward = [0.0; MAX_POINTS * 5];
    let mut correction = [0.0; MAX_POINTS * 5];
    for index in 0..count {
        rhs[index] = v[32 + index] as f64 / SCALE;
        x[index] = v[32 + count + index] as f64 / SCALE;
    }
    let nxy = nx * ny;
    for sweep in 0..sweeps {
        apply(nx, ny, nz, &d, &c, &x, &mut applied);
        for index in 0..count { residual[index] = rhs[index] - applied[index]; }
        for point in 0..points {
            let ix = point % nx;
            let iy = (point / nx) % ny;
            let iz = point / nxy;
            let mut local = [0.0; 5];
            for row in 0..5 { local[row] = residual[point * 5 + row]; }
            if ix > 0 { for row in 0..5 { local[row] -= c[0] * forward[(point - 1) * 5 + row]; } }
            if iy > 0 { for row in 0..5 { local[row] -= c[1] * forward[(point - nx) * 5 + row]; } }
            if iz > 0 { for row in 0..5 { local[row] -= c[2] * forward[(point - nxy) * 5 + row]; } }
            let solved = solve5(&d, local)?;
            for row in 0..5 { forward[point * 5 + row] = solved[row]; }
        }
        for point in (0..points).rev() {
            let ix = point % nx;
            let iy = (point / nx) % ny;
            let iz = point / nxy;
            let mut local = [0.0; 5];
            for row in 0..5 {
                for column in 0..5 { local[row] += d[row * 5 + column] * forward[point * 5 + column]; }
            }
            if ix + 1 < nx { for row in 0..5 { local[row] -= c[0] * correction[(point + 1) * 5 + row]; } }
            if iy + 1 < ny { for row in 0..5 { local[row] -= c[1] * correction[(point + nx) * 5 + row]; } }
            if iz + 1 < nz { for row in 0..5 { local[row] -= c[2] * correction[(point + nxy) * 5 + row]; } }
            let solved = solve5(&d, local)?;
            for row in 0..5 { correction[point * 5 + row] = solved[row]; }
        }
        for index in 0..count { x[index] += correction[index]; }
        apply(nx, ny, nz, &d, &c, &x, &mut applied);
        let residual_norm = (0..count).map(|i| (rhs[i] - applied[i]).powi(2)).sum::<f64>().sqrt();
        if !residual_norm.is_finite() { return None; }
        write_le(output, sweep * 8, residual_norm);
    }
    for index in 0..count { write_le(output, (sweeps + index) * 8, x[index]); }
    Some(8 * (sweeps + count))
}

#[no_mangle]
pub unsafe extern "C" fn npb_lu_block_ssor(values: *const i64, length: usize,
                                             output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 42 || length > 32 + 10 * MAX_POINTS { return -1; }
    let v = slice::from_raw_parts(values, length);
    let (nx, ny, nz, sweeps) = match valid(v) { Some(shape) => shape, None => return -1 };
    let required = 8 * (sweeps + 5 * nx * ny * nz);
    if output.is_null() || output_capacity < required { return -2; }
    match run(v, nx, ny, nz, sweeps, output) {
        Some(bytes) => bytes as i64,
        None => -1,
    }
}
