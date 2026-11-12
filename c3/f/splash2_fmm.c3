module splash2_fmm;

const usz MAX_PARTICLES = 48;
const usz BOXES = 16;
const usz ORDER = 32;
const usz STRIDE = ORDER + 1;
extern fn double log(double value);
extern fn int abs(int value);

fn long splash2_fmm(double* input, usz input_length, double* output, usz output_capacity)
    @export("splash2_fmm") {
    if (input == null || input_length < 7 || input_length > 145) return -1;
    double requested = input[0];
    if (!(requested >= 2.0 && requested <= 48.0) || requested != (double)(int)requested) return -1;
    usz count = (usz)requested;
    if (input_length != 1 + 3 * count) return -1;
    double[MAX_PARTICLES] x; double[MAX_PARTICLES] y; double[MAX_PARTICLES] charge;
    int[MAX_PARTICLES] box;
    for (usz i = 0; i < count; i++) {
        double px = input[1 + 3 * i], py = input[2 + 3 * i], q = input[3 + 3 * i];
        if (!(px >= 0.0 && px < 8.0) || px != (double)(int)px ||
            !(py >= 0.0 && py < 8.0) || py != (double)(int)py ||
            !(q >= -3.0 && q <= 3.0) || q != (double)(int)q) return -1;
        x[i] = px; y[i] = py; charge[i] = q;
        box[i] = ((int)py / 2) * 4 + (int)px / 2;
        for (usz j = 0; j < i; j++) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    if (output == null || output_capacity < count) return -2;
    double[BOXES * STRIDE] mr; double[BOXES * STRIDE] mi;
    double[BOXES * STRIDE] lr; double[BOXES * STRIDE] li;
    for (usz i = 0; i < BOXES * STRIDE; i++) { mr[i] = 0.0; mi[i] = 0.0; lr[i] = 0.0; li[i] = 0.0; }
    for (usz i = 0; i < count; i++) {
        int b = box[i], bx = b % 4, by = b / 4;
        double zr = x[i] - (2.0 * bx + 1.0), zi = y[i] - (2.0 * by + 1.0);
        double pr = 1.0, pi = 0.0;
        mr[b * STRIDE] += charge[i];
        for (usz k = 1; k <= ORDER; k++) {
            double nr = pr * zr - pi * zi, ni = pr * zi + pi * zr;
            pr = nr; pi = ni;
            mr[b * STRIDE + k] += charge[i] * pr;
            mi[b * STRIDE + k] += charge[i] * pi;
        }
    }
    for (int target = 0; target < 16; target++) {
        int tx = target % 4, ty = target / 4;
        for (int source = 0; source < 16; source++) {
            int sx = source % 4, sy = source / 4;
            int dbx = tx - sx, dby = ty - sy;
            if (abs(dbx) <= 1 && abs(dby) <= 1) continue;
            double dx = 2.0 * dbx, dy = 2.0 * dby, r2 = dx * dx + dy * dy;
            double[65] ir; double[65] ii;
            ir[0] = 1.0; ii[0] = 0.0;
            double odr = dx / r2, odi = -dy / r2;
            for (int p = 1; p <= 64; p++) {
                ir[p] = ir[p-1] * odr - ii[p-1] * odi;
                ii[p] = ir[p-1] * odi + ii[p-1] * odr;
            }
            double constant = mr[source * STRIDE] * 0.5 * log(r2);
            for (int k = 1; k <= 32; k++)
                constant -= (mr[source * STRIDE + k] * ir[k] - mi[source * STRIDE + k] * ii[k]) / (double)k;
            lr[target * STRIDE] += constant;
            for (int n = 1; n <= 32; n++) {
                double sr = 0.0, si = 0.0;
                for (int k = 1; k <= 32; k++) {
                    double choose = 1.0;
                    for (int j = 1; j <= n; j++) choose *= (double)(k + j - 1) / (double)j;
                    double scale = choose / (double)k;
                    int p = k + n;
                    sr += scale * (mr[source * STRIDE + k] * ir[p] - mi[source * STRIDE + k] * ii[p]);
                    si += scale * (mr[source * STRIDE + k] * ii[p] + mi[source * STRIDE + k] * ir[p]);
                }
                double qscale = (n % 2 == 1 ? 1.0 : -1.0) / (double)n;
                double mscale = (n % 2 == 1 ? -1.0 : 1.0);
                lr[target * STRIDE + n] += mr[source * STRIDE] * qscale * ir[n] - mscale * sr;
                li[target * STRIDE + n] += mr[source * STRIDE] * qscale * ii[n] - mscale * si;
            }
        }
    }
    for (usz i = 0; i < count; i++) {
        int b = box[i], bx = b % 4, by = b / 4;
        double wr = x[i] - (2.0 * bx + 1.0), wi = y[i] - (2.0 * by + 1.0);
        double pr = 1.0, pi = 0.0, value = lr[b * STRIDE];
        for (int n = 1; n <= 32; n++) {
            double nr = pr * wr - pi * wi, ni = pr * wi + pi * wr;
            pr = nr; pi = ni;
            value += lr[b * STRIDE + n] * pr - li[b * STRIDE + n] * pi;
        }
        for (usz j = 0; j < count; j++) {
            if (j == i) continue;
            int sb = box[j], sx = sb % 4, sy = sb / 4;
            if (abs(bx - sx) > 1 || abs(by - sy) > 1) continue;
            double dx = x[j] - x[i], dy = y[j] - y[i];
            value += charge[j] * 0.5 * log(dx * dx + dy * dy);
        }
        output[i] = value;
    }
    return (long)count;
}
