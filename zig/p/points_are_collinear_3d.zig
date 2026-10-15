/// Check whether three bounded integer points lie on one 3D line.
export fn points_are_collinear_3d(values: [*]const i64, length: usize) i64 {
    if (length != 9) return -1;
    for (0..9) |index| {
        if (values[index] < -10000 or values[index] > 10000) return -1;
    }

    const abx = values[3] - values[0];
    const aby = values[4] - values[1];
    const abz = values[5] - values[2];
    const acx = values[6] - values[0];
    const acy = values[7] - values[1];
    const acz = values[8] - values[2];
    const cross_x = aby * acz - abz * acy;
    const cross_y = abz * acx - abx * acz;
    const cross_z = abx * acy - aby * acx;
    return if (cross_x == 0 and cross_y == 0 and cross_z == 0) 1 else 0;
}
