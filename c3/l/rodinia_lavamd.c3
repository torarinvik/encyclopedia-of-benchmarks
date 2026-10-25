module rodinia_lavamd;
import "math";

const double LMD_BIAS = 1000000000000.0, LMD_SCALE = 1000000.0;

fn long lmd_round(double value) {
    double scaled = value * LMD_SCALE;
    if (scaled < 0.0) return -(long)math.floor(-scaled + 0.5);
    return (long)math.floor(scaled + 0.5);
}

// LavaMD source-order screened pair interactions over home and one neighbor box.
fn long rodinia_lavamd(long* input, usz length) @export("rodinia_lavamd") {
    if (input == null || length < 12 || length > 42 || input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4) return -1;
    usz home_n = (usz)input[0], neighbor_n = (usz)input[1];
    if (length != 2 + 5 * (home_n + neighbor_n)) return -1;
    double[2][4][5] p;
    usz[2] counts = {home_n, neighbor_n};
    usz cursor = 2;
    for (usz box = 0; box < 2; box++) for (usz i = 0; i < counts[box]; i++) for (usz c = 0; c < 5; c++) {
        long raw = input[cursor++];
        if (raw < 0 || raw > 1000000) return -1;
        p[box][i][c] = (double)raw / LMD_SCALE;
    }
    double total = 0.0;
    for (usz i = 0; i < home_n; i++) {
        double fv = 0.0, fx = 0.0, fy = 0.0, fz = 0.0;
        for (usz box = 0; box < 2; box++) for (usz j = 0; j < counts[box]; j++) {
            double* a = p[0][i]; double* b = p[box][j];
            double dot = a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
            double r2 = a[0] + b[0] - dot;
            double vij = math.exp(-(0.5 * r2)); double fs = 2.0 * vij;
            double dx = a[1] - b[1], dy = a[2] - b[2], dz = a[3] - b[3];
            fv += b[4] * vij; fx += b[4] * (fs * dx); fy += b[4] * (fs * dy); fz += b[4] * (fs * dz);
        }
        total += (double)(i + 1) * ((fv + fx) + fy + fz);
    }
    return (long)LMD_BIAS + lmd_round(total);
}
