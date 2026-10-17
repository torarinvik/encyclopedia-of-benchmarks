module unscented_kalman_filter;
extern fn double sqrt(double value);

fn bool sigma_points(double x, double y, double p00, double p01, double p11, double[5][2]* points) {
    double l00 = sqrt(2.0 * p00);
    if (l00 <= 0.0) return false;
    double l10 = (2.0 * p01) / l00;
    double remainder = 2.0 * p11 - l10 * l10;
    if (remainder <= 0.0) return false;
    double l11 = sqrt(remainder);
    points[0][0] = x;        points[0][1] = y;
    points[1][0] = x + l00;  points[1][1] = y + l10;
    points[2][0] = x;        points[2][1] = y + l11;
    points[3][0] = x - l00;  points[3][1] = y - l10;
    points[4][0] = x;        points[4][1] = y - l11;
    return true;
}

fn double unscented_kalman_filter(long* v, usz n) @export("unscented_kalman_filter") {
    const double BAD = -1.0e300;
    if (v == null || n < 10 || n > 17) return BAD;
    long steps = v[0];
    if (steps < 1 || steps > 8 || n != (usz)(9 + steps)) return BAD;
    if (v[1] < -1000 || v[1] > 1000 || v[2] < -1000 || v[2] > 1000) return BAD;
    if (v[3] < 500 || v[3] > 1000 || v[4] < -100 || v[4] > 100 || v[5] < 500 || v[5] > 1000) return BAD;
    if (v[6] < 10 || v[6] > 50 || v[7] < 10 || v[7] > 50 || v[8] < 10 || v[8] > 100) return BAD;
    for (usz i = 9; i < n; i++) if (v[i] < -2000 || v[i] > 2000) return BAD;

    double scale = 1000.0;
    double x = (double)v[1] / scale, y = (double)v[2] / scale;
    double p00 = (double)v[3] / scale, p01 = (double)v[4] / scale, p11 = (double)v[5] / scale;
    double q0 = (double)v[6] / scale, q1 = (double)v[7] / scale, noise = (double)v[8] / scale;
    for (long t = 0; t < steps; t++) {
        double sigma[5][2] = {{0}}, propagated[5][2] = {{0}};
        if (!sigma_points(x, y, p00, p01, p11, &sigma)) return BAD;
        for (usz i = 0; i < 5; i++) {
            double sx = sigma[i][0], sy = sigma[i][1];
            propagated[i][0] = sx + 0.1 * sy;
            propagated[i][1] = sy + 0.05 * sx * sx;
        }
        double mean_x = 0.0, mean_y = 0.0;
        for (usz i = 1; i < 5; i++) {
            mean_x += 0.25 * propagated[i][0];
            mean_y += 0.25 * propagated[i][1];
        }
        double next_p00 = 2.0 * (propagated[0][0] - mean_x) * (propagated[0][0] - mean_x);
        double next_p01 = 2.0 * (propagated[0][0] - mean_x) * (propagated[0][1] - mean_y);
        double next_p11 = 2.0 * (propagated[0][1] - mean_y) * (propagated[0][1] - mean_y);
        for (usz i = 1; i < 5; i++) {
            double dx = propagated[i][0] - mean_x, dy = propagated[i][1] - mean_y;
            next_p00 += 0.25 * dx * dx;
            next_p01 += 0.25 * dx * dy;
            next_p11 += 0.25 * dy * dy;
        }
        x = mean_x; y = mean_y;
        p00 = next_p00 + q0; p01 = 0.5 * (next_p01 + next_p01); p11 = next_p11 + q1;

        if (!sigma_points(x, y, p00, p01, p11, &sigma)) return BAD;
        double mapped[5] = {0};
        for (usz i = 0; i < 5; i++) mapped[i] = 0.05 * sigma[i][0] * sigma[i][0] + sigma[i][1];
        double expected_z = 0.0;
        for (usz i = 1; i < 5; i++) expected_z += 0.25 * mapped[i];
        double innovation = noise, cross0 = 0.0, cross1 = 0.0;
        for (usz i = 0; i < 5; i++) {
            double weight = i == 0 ? 2.0 : 0.25;
            double dx = sigma[i][0] - x, dy = sigma[i][1] - y, dz = mapped[i] - expected_z;
            innovation += weight * dz * dz;
            cross0 += weight * dx * dz;
            cross1 += weight * dy * dz;
        }
        if (innovation <= 0.0) return BAD;
        double k0 = cross0 / innovation, k1 = cross1 / innovation;
        double residual = (double)v[9 + (usz)t] / scale - expected_z;
        x += k0 * residual; y += k1 * residual;
        double u0 = k0 * innovation, u1 = k1 * innovation, old_p01 = p01;
        p00 -= u0 * k0;
        p01 = old_p01 - 0.5 * (u0 * k1 + u1 * k0);
        p11 -= u1 * k1;
    }
    return x;
}
