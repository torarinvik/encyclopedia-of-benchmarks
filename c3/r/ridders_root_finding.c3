module ridders_root_finding;

extern fn double sqrt(double value);

const usz MAX_INPUT_LENGTH = 6;

fn bool integer_field(double x, long lo, long hi, long* decoded) {
    if (!(x == x) || x < (double)lo || x > (double)hi || (double)(long)x != x) return false;
    *decoded = (long)x;
    return true;
}

fn double polynomial(long id, double x) {
    if (id == 0) return x*x-2.0;
    if (id == 1) return x*x*x-2.0;
    if (id == 2) return x*x*x+x-1.0;
    return x;
}

fn bool opposite(double a, double b) { return (a < 0.0) != (b < 0.0); }

fn long solve(long id, double left0, double right0, double tolerance, long iterations,
              double* root) {
    double left = left0; double right = right0;
    double f_left = polynomial(id, left); double f_right = polynomial(id, right);
    if (f_left == 0.0) { *root = left; return 1L; }
    if (f_right == 0.0) { *root = right; return 1L; }
    for (long step = 0; step < iterations; step++) {
        if (right-left <= tolerance) { *root = (left+right)*0.5; return 1L; }
        double middle = (left+right)*0.5;
        double f_middle = polynomial(id, middle);
        if (f_middle == 0.0) { *root = middle; return 1L; }
        double radicand = f_middle*f_middle-f_left*f_right;
        if (!(radicand == radicand) || radicand <= 0.0 || radicand > 1e308) return -3L;
        double denominator = sqrt(radicand);
        if (!(denominator == denominator) || denominator == 0.0 || denominator > 1e308) return -3L;
        double direction = f_left < f_right ? -1.0 : 1.0;
        double candidate = middle+(middle-left)*direction*f_middle/denominator;
        if (!(candidate == candidate) || candidate <= left || candidate >= right) return -3L;
        double f_candidate = polynomial(id, candidate);
        if (f_candidate == 0.0) { *root = candidate; return 1L; }
        if (opposite(f_left, f_candidate)) { right = candidate; f_right = f_candidate; }
        else { left = candidate; f_left = f_candidate; }
        if (right-left <= tolerance) { *root = (left+right)*0.5; return 1L; }
    }
    return -3L;
}

fn long ridders_root_finding(double* input, usz input_length,
                             double* output, usz output_capacity)
    @export("ridders_root_finding") {
    if (input == null || input_length != 5 || input_length > MAX_INPUT_LENGTH) return -1L;
    long id; long left_milli; long right_milli; long tolerance_micro; long iterations;
    if (!integer_field(input[0], 0, 3, &id) ||
        !integer_field(input[1], -3000, 3000, &left_milli) ||
        !integer_field(input[2], -3000, 3000, &right_milli) ||
        !integer_field(input[3], 1, 1000, &tolerance_micro) ||
        !integer_field(input[4], 24, 32, &iterations) || left_milli >= right_milli) return -1L;
    double left = (double)left_milli/1000.0; double right = (double)right_milli/1000.0;
    double f_left = polynomial(id, left); double f_right = polynomial(id, right);
    if (f_left != 0.0 && f_right != 0.0 && !opposite(f_left, f_right)) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    double root = 0.0;
    long status = solve(id, left, right, (double)tolerance_micro/1000000.0, iterations, &root);
    if (status != 1L || !(root == root) || root > 1e308 || root < -1e308) return status == 1L ? -3L : status;
    output[0] = root;
    return 1L;
}
