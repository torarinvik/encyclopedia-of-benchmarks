module doe_minigmg_restriction;

const double INVALID_RESULT = -1.0e300;

fn double doe_minigmg_restriction(long* values, usz length) @export("doe_minigmg_restriction") {
    if (values == null || length < 11 || length > 515) return INVALID_RESULT;
    long nx_raw = values[0], ny_raw = values[1], nz_raw = values[2];
    if (nx_raw < 2 || nx_raw > 8 || nx_raw % 2 != 0 ||
        ny_raw < 2 || ny_raw > 8 || ny_raw % 2 != 0 ||
        nz_raw < 2 || nz_raw > 8 || nz_raw % 2 != 0) return INVALID_RESULT;

    usz nx = (usz)nx_raw, ny = (usz)ny_raw, nz = (usz)nz_raw;
    usz cells = nx * ny * nz;
    if (length != 3 + cells) return INVALID_RESULT;
    for (usz q = 0; q < cells; q++)
        if (values[3 + q] < -32768 || values[3 + q] > 32767) return INVALID_RESULT;

    usz coarse_nx = nx / 2, coarse_ny = ny / 2, coarse_nz = nz / 2;
    usz plane = nx * ny;
    double checksum = 0.0;
    usz coarse_index = 0;
    for (usz k = 0; k < coarse_nz; k++) {
        for (usz j = 0; j < coarse_ny; j++) {
            for (usz i = 0; i < coarse_nx; i++) {
                usz base = 3 + 2 * i + 2 * j * nx + 2 * k * plane;
                double sum = (double)values[base] + (double)values[base + 1] +
                    (double)values[base + nx] + (double)values[base + nx + 1] +
                    (double)values[base + plane] + (double)values[base + plane + 1] +
                    (double)values[base + plane + nx] + (double)values[base + plane + nx + 1];
                double restricted = sum * 0.125;
                double weight = (double)(coarse_index + 1);
                checksum += weight * restricted * restricted;
                coarse_index++;
            }
        }
    }
    return checksum;
}
