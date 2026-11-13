module adaptive_gauss_kronrod_15_quadrature;

extern fn double exp(double value);
extern fn double sin(double value);
extern fn double fabs(double value);

const usz MAX_INPUT_LENGTH = 6;
const long MAX_INTERVALS = 16;
const double NODES[7] = {0.9914553711208126392, 0.9491079123427585245, 0.8648644233597690728,
    0.7415311855993944399, 0.5860872354676911303, 0.4058451513773971669, 0.2077849550078984676};
const double KW[7] = {0.022935322010529225, 0.06309209262997855, 0.10479001032225018,
    0.14065325971552592, 0.16900472663926790, 0.19035057806478541, 0.20443294007529889};
const double GW[3] = {0.12948496616886969, 0.27970539148927667, 0.38183005050511894};

fn bool integer_field(double x, long lo, long hi) {
    return x == x && x >= (double)lo && x <= (double)hi && (double)(long)x == x;
}

fn double sample(long id, double x) {
    if (id == 0) return exp(4.0 * x);
    if (id == 1) return sin(10.0 * x);
    if (id == 2) return 1.0 / (1.0 + 9.0 * x * x);
    double x2 = x * x; double x4 = x2 * x2; double x8 = x4 * x4;
    return x8 * x4 * x2;
}

fn void pair_estimate(long id, double a, double b, double* kr, double* gr) {
    double center = (a + b) * 0.5; double half = (b - a) * 0.5;
    double fc = sample(id, center);
    double k = 0.2094821410847278280 * fc;
    double g = 0.4179591836734693878 * fc;
    for (long i = 0; i < 7; i++) {
        double offset = half * NODES[i];
        double pair = sample(id, center - offset) + sample(id, center + offset);
        k += KW[i] * pair;
        if (i == 1) g += GW[0] * pair;
        if (i == 3) g += GW[1] * pair;
        if (i == 5) g += GW[2] * pair;
    }
    *kr = half * k; *gr = half * g;
}

fn long adaptive_gauss_kronrod_15_quadrature(double* input, usz input_length,
    double* output, usz output_capacity) @export("adaptive_gauss_kronrod_15_quadrature") {
    if (input == null || input_length != 5 || input_length > MAX_INPUT_LENGTH) return -1L;
    if (!integer_field(input[0], 0, 3) || !integer_field(input[1], -1000000, 1000000) ||
        !integer_field(input[2], -1000000, 1000000) || !integer_field(input[3], 6, 8) ||
        !integer_field(input[4], 1, MAX_INTERVALS)) return -1L;
    long id = (long)input[0]; long a_micro = (long)input[1]; long b_micro = (long)input[2];
    long exponent = (long)input[3]; long limit = (long)input[4];
    if (a_micro > b_micro) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    double a = (double)a_micro / 1000000.0; double b = (double)b_micro / 1000000.0;
    if (a == b) { output[0] = 0.0; return 1L; }
    double lefts[16]; double rights[16]; double values[16]; double errors[16];
    double k; double g; pair_estimate(id, a, b, &k, &g);
    lefts[0] = a; rights[0] = b; values[0] = k; errors[0] = fabs(k - g);
    long count = 1; double tolerance = 1.0;
    for (long i = 0; i < exponent; i++) tolerance *= 0.1;
    while (true) {
        double total = 0.0; double error = 0.0;
        for (long i = 0; i < count; i++) { total += values[i]; error += errors[i]; }
        double scale = fabs(total) > 1.0 ? fabs(total) : 1.0;
        if (error <= tolerance * scale) { output[0] = total; return 1L; }
        if (count >= limit) return -3L;
        long best = 0;
        for (long i = 1; i < count; i++) {
            if (errors[i] > errors[best] || (errors[i] == errors[best] && lefts[i] < lefts[best])) best = i;
        }
        double l = lefts[best]; double r = rights[best]; double m = (l + r) * 0.5;
        double lk; double lg; double rk; double rg;
        pair_estimate(id, l, m, &lk, &lg); pair_estimate(id, m, r, &rk, &rg);
        lefts[best] = l; rights[best] = m; values[best] = lk; errors[best] = fabs(lk - lg);
        lefts[count] = m; rights[count] = r; values[count] = rk; errors[count] = fabs(rk - rg);
        count++;
    }
}
