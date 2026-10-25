#[no_mangle]
pub unsafe extern "C" fn doe_minigmg_restriction(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 11 || length > 515 {
        return -1.0e300;
    }
    let values = std::slice::from_raw_parts(values, length);
    let (nx_raw, ny_raw, nz_raw) = (values[0], values[1], values[2]);
    if !(2..=8).contains(&nx_raw) || nx_raw % 2 != 0 ||
       !(2..=8).contains(&ny_raw) || ny_raw % 2 != 0 ||
       !(2..=8).contains(&nz_raw) || nz_raw % 2 != 0 {
        return -1.0e300;
    }

    let (nx, ny, nz) = (nx_raw as usize, ny_raw as usize, nz_raw as usize);
    let cells = nx * ny * nz;
    if length != 3 + cells || values[3..].iter().any(|&value| !(-32768..=32767).contains(&value)) {
        return -1.0e300;
    }

    let (coarse_nx, coarse_ny, coarse_nz) = (nx / 2, ny / 2, nz / 2);
    let plane = nx * ny;
    let mut checksum = 0.0;
    let mut coarse_index = 0usize;
    for k in 0..coarse_nz {
        for j in 0..coarse_ny {
            for i in 0..coarse_nx {
                let base = 3 + 2 * i + 2 * j * nx + 2 * k * plane;
                let sum = values[base] as f64 + values[base + 1] as f64 +
                    values[base + nx] as f64 + values[base + nx + 1] as f64 +
                    values[base + plane] as f64 + values[base + plane + 1] as f64 +
                    values[base + plane + nx] as f64 + values[base + plane + nx + 1] as f64;
                let restricted = sum * 0.125;
                let weight = (coarse_index + 1) as f64;
                checksum += weight * restricted * restricted;
                coarse_index += 1;
            }
        }
    }
    checksum
}
