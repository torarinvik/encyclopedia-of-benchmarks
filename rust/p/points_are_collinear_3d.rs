/// Check whether three bounded integer points lie on one 3D line.
#[no_mangle]
pub unsafe extern "C" fn points_are_collinear_3d(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 9 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&value| !(-10000..=10000).contains(&value)) {
        return -1;
    }

    let abx = values[3] - values[0];
    let aby = values[4] - values[1];
    let abz = values[5] - values[2];
    let acx = values[6] - values[0];
    let acy = values[7] - values[1];
    let acz = values[8] - values[2];
    let cross_x = aby * acz - abz * acy;
    let cross_y = abz * acx - abx * acz;
    let cross_z = abx * acy - aby * acx;
    (cross_x == 0 && cross_y == 0 && cross_z == 0) as i64
}
