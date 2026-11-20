module tanh_sinh_double_exponential_quadrature;

extern fn double exp(double value);
extern fn double sqrt(double value);

const usz MAX_PARSEABLE_INPUT_LENGTH = 3;
const double PI_PINNED = 3.14159265358979323846264338327950288;

fn bool exact_integer(double value, long low, long high, long* decoded) {
    if (!(value == value) || value < (double)low || value > (double)high || (double)(long)value != value) return false;
    *decoded = (long)value;
    return true;
}

fn double integrate(long function_id, long p) {
    double h = 1.0 / (double)(1L << p);
    double half_pi = PI_PINNED / 2.0;
    long limit = 3L * (1L << p);
    double total = 0.0;
    for (long j=-limit; j<=limit; j++) {
        double t = (double)j * h;
        double exp_t = exp(t);
        double exp_minus_t = exp(-t);
        double sinh_t = (exp_t-exp_minus_t)*0.5;
        double cosh_t = (exp_t+exp_minus_t)*0.5;
        double u = half_pi*sinh_t;
        double abs_u = u < 0.0 ? -u : u;
        double q = exp(-2.0*abs_u);
        double one_plus_q = 1.0+q;
        double sech_squared = (4.0*q)/(one_plus_q*one_plus_q);
        double magnitude_x = (1.0-q)/one_plus_q;
        double x = u >= 0.0 ? magnitude_x : -magnitude_x;
        double jacobian = (half_pi*cosh_t)*sech_squared;
        double sample;
        if (function_id == 0) sample = 1.0;
        else if (function_id == 1) sample = x*x;
        else if (function_id == 2) sample = 1.0/sqrt(sech_squared);
        else if (u >= 0.0) sample = 1.0/sqrt((2.0*q)/one_plus_q);
        else sample = 1.0/sqrt(2.0/one_plus_q);
        double transformed = sample*jacobian;
        total += h*transformed;
    }
    return total;
}

fn long tanh_sinh_double_exponential_quadrature(double* input, usz input_length,
                                               double* output, usz output_capacity)
    @export("tanh_sinh_double_exponential_quadrature") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    long function_id, p;
    if (input_length != 2 || !exact_integer(input[0],0,3,&function_id) || !exact_integer(input[1],2,4,&p)) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    double value = integrate(function_id,p);
    if (!(value == value) || value > 1e308 || value < -1e308) return -1L;
    output[0] = value;
    return 1L;
}
