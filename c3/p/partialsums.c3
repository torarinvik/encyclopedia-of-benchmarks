module partialsums;

const MAX_N = 10000;
const OUTPUT_COUNT = 9;
extern fn double sin(double value);
extern fn double cos(double value);
extern fn double sqrt(double value);
extern fn double trunc(double value);

fn long partialsums(double* input, usz length, double* output, usz capacity)
    @export("partialsums") {
    if (input == null || length != 1 || trunc(input[0]) != input[0] ||
        input[0] < 1.0 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    double geometric = 0.0, inverse_sqrt = 0.0, flint = 0.0, cookson = 0.0;
    double[2] telescoping = {0.0, 0.0}, harmonic = {0.0, 0.0};
    double[2] zeta = {0.0, 0.0}, alternating = {0.0, 0.0}, gregory = {0.0, 0.0};
    double term = 1.0;
    usz vector_limit = n + (n & 1);
    for (usz k = 1; k <= vector_limit; k++) {
        double kd = (double)k;
        usz lane = (k - 1) & 1;
        if (k <= n) {
            double k3 = kd * kd * kd;
            double s = sin(kd), c = cos(kd);
            geometric += term;
            term *= 2.0 / 3.0;
            inverse_sqrt += 1.0 / sqrt(kd);
            flint += 1.0 / (k3 * s * s);
            cookson += 1.0 / (k3 * c * c);
        }
        telescoping[lane] += 1.0 / (kd * (kd + 1.0));
        harmonic[lane] += 1.0 / kd;
        zeta[lane] += 1.0 / (kd * kd);
        alternating[lane] += (lane == 0 ? 1.0 : -1.0) / kd;
        gregory[lane] += (lane == 0 ? 1.0 : -1.0) / (2.0 * kd - 1.0);
    }
    if (output == null || capacity < OUTPUT_COUNT) return -2;
    output[0] = geometric;
    output[1] = inverse_sqrt;
    output[2] = telescoping[0] + telescoping[1];
    output[3] = flint;
    output[4] = cookson;
    output[5] = harmonic[0] + harmonic[1];
    output[6] = zeta[0] + zeta[1];
    output[7] = alternating[0] + alternating[1];
    output[8] = gregory[0] + gregory[1];
    return OUTPUT_COUNT;
}
