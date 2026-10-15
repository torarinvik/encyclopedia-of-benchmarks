module points_are_collinear_3d;

// Check whether three bounded integer points lie on one 3D line.
fn long points_are_collinear_3d(long* values, usz length) @export("points_are_collinear_3d") {
    if (values == null || length != 9) return -1;
    for (usz index = 0; index < 9; index++) {
        if (values[index] < -10000 || values[index] > 10000) return -1;
    }

    long abx = values[3] - values[0];
    long aby = values[4] - values[1];
    long abz = values[5] - values[2];
    long acx = values[6] - values[0];
    long acy = values[7] - values[1];
    long acz = values[8] - values[2];
    long cross_x = aby * acz - abz * acy;
    long cross_y = abz * acx - abx * acz;
    long cross_z = abx * acy - aby * acx;
    return cross_x == 0 && cross_y == 0 && cross_z == 0 ? 1 : 0;
}
