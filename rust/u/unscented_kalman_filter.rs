const BAD: f64 = -1.0e300;
const SCALE: f64 = 1000.0;

fn sigma_points(x: f64, y: f64, p00: f64, p01: f64, p11: f64) -> Option<[[f64; 2]; 5]> {
    let l00 = (2.0 * p00).sqrt();
    if !(l00 > 0.0) { return None; }
    let l10 = (2.0 * p01) / l00;
    let remainder = 2.0 * p11 - l10 * l10;
    if !(remainder > 0.0) { return None; }
    let l11 = remainder.sqrt();
    Some([
        [x, y],
        [x + l00, y + l10],
        [x, y + l11],
        [x - l00, y - l10],
        [x, y - l11],
    ])
}

#[no_mangle]
pub unsafe extern "C" fn unscented_kalman_filter(v: *const i64, n: usize) -> f64 {
    if v.is_null() || n < 10 || n > 17 { return BAD; }
    let v = std::slice::from_raw_parts(v, n);
    let steps = v[0];
    if steps < 1 || steps > 8 || n != (9 + steps) as usize { return BAD; }
    if v[1] < -1000 || v[1] > 1000 || v[2] < -1000 || v[2] > 1000 { return BAD; }
    if v[3] < 500 || v[3] > 1000 || v[4] < -100 || v[4] > 100 || v[5] < 500 || v[5] > 1000 { return BAD; }
    if v[6] < 10 || v[6] > 50 || v[7] < 10 || v[7] > 50 || v[8] < 10 || v[8] > 100 { return BAD; }
    if v[9..].iter().any(|z| *z < -2000 || *z > 2000) { return BAD; }

    let (mut x, mut y) = (v[1] as f64 / SCALE, v[2] as f64 / SCALE);
    let (mut p00, mut p01, mut p11) = (v[3] as f64 / SCALE, v[4] as f64 / SCALE, v[5] as f64 / SCALE);
    let (q0, q1, noise) = (v[6] as f64 / SCALE, v[7] as f64 / SCALE, v[8] as f64 / SCALE);
    for t in 0..steps as usize {
        let Some(sigma) = sigma_points(x, y, p00, p01, p11) else { return BAD; };
        let mut propagated = [[0.0; 2]; 5];
        for i in 0..5 {
            let (sx, sy) = (sigma[i][0], sigma[i][1]);
            propagated[i][0] = sx + 0.1 * sy;
            propagated[i][1] = sy + 0.05 * sx * sx;
        }
        let (mut mean_x, mut mean_y) = (0.0, 0.0);
        for point in propagated.iter().skip(1) {
            mean_x += 0.25 * point[0];
            mean_y += 0.25 * point[1];
        }
        let dx0 = propagated[0][0] - mean_x;
        let dy0 = propagated[0][1] - mean_y;
        let (mut next_p00, mut next_p01, mut next_p11) = (2.0 * dx0 * dx0, 2.0 * dx0 * dy0, 2.0 * dy0 * dy0);
        for point in propagated.iter().skip(1) {
            let (dx, dy) = (point[0] - mean_x, point[1] - mean_y);
            next_p00 += 0.25 * dx * dx;
            next_p01 += 0.25 * dx * dy;
            next_p11 += 0.25 * dy * dy;
        }
        x = mean_x;
        y = mean_y;
        p00 = next_p00 + q0;
        p01 = 0.5 * (next_p01 + next_p01);
        p11 = next_p11 + q1;

        let Some(sigma) = sigma_points(x, y, p00, p01, p11) else { return BAD; };
        let mut mapped = [0.0; 5];
        for i in 0..5 { mapped[i] = 0.05 * sigma[i][0] * sigma[i][0] + sigma[i][1]; }
        let mut expected_z = 0.0;
        for z in mapped.iter().skip(1) { expected_z += 0.25 * *z; }
        let (mut innovation, mut cross0, mut cross1) = (noise, 0.0, 0.0);
        for i in 0..5 {
            let weight = if i == 0 { 2.0 } else { 0.25 };
            let (dx, dy, dz) = (sigma[i][0] - x, sigma[i][1] - y, mapped[i] - expected_z);
            innovation += weight * dz * dz;
            cross0 += weight * dx * dz;
            cross1 += weight * dy * dz;
        }
        if !(innovation > 0.0) || !innovation.is_finite() { return BAD; }
        let (k0, k1) = (cross0 / innovation, cross1 / innovation);
        let residual = v[9 + t] as f64 / SCALE - expected_z;
        x += k0 * residual;
        y += k1 * residual;
        let (u0, u1, old_p01) = (k0 * innovation, k1 * innovation, p01);
        p00 -= u0 * k0;
        p01 = old_p01 - 0.5 * (u0 * k1 + u1 * k0);
        p11 -= u1 * k1;
    }
    x
}
