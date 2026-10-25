/// Rodinia source-order screened pair interactions over a home and one neighbor box.
#[no_mangle]
pub extern "C" fn rodinia_lavamd(input: *const i64, length: usize) -> i64 {
    const BIAS: i64 = 1_000_000_000_000;
    if input.is_null() || length < 12 || length > 42 { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=4).contains(&v[0]) || !(1..=4).contains(&v[1]) { return -1; }
    let home_n = v[0] as usize; let neighbor_n = v[1] as usize;
    if length != 2 + 5 * (home_n + neighbor_n) { return -1; }
    let mut particles = [[[0.0f64; 5]; 4]; 2];
    let counts = [home_n, neighbor_n];
    let mut cursor = 2;
    for box_index in 0..2 {
        for p in 0..counts[box_index] {
            for c in 0..5 {
                let raw = v[cursor]; cursor += 1;
                if !(0..=1_000_000).contains(&raw) { return -1; }
                particles[box_index][p][c] = raw as f64 / 1_000_000.0;
            }
        }
    }
    let mut total = 0.0f64;
    for i in 0..home_n {
        let (mut fv, mut fx, mut fy, mut fz) = (0.0, 0.0, 0.0, 0.0);
        let a = particles[0][i];
        for box_index in 0..2 {
            for j in 0..counts[box_index] {
                let b = particles[box_index][j];
                let dot = a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
                let r2 = a[0] + b[0] - dot;
                let vij = (-(0.5 * r2)).exp(); let fs = 2.0 * vij;
                let dx = a[1] - b[1]; let dy = a[2] - b[2]; let dz = a[3] - b[3];
                fv += b[4] * vij; fx += b[4] * (fs * dx); fy += b[4] * (fs * dy); fz += b[4] * (fs * dz);
            }
        }
        total += (i + 1) as f64 * ((fv + fx) + fy + fz);
    }
    let scaled = total * 1_000_000.0;
    let rounded = if scaled < 0.0 { -((-scaled + 0.5).floor() as i64) } else { (scaled + 0.5).floor() as i64 };
    BIAS + rounded
}
