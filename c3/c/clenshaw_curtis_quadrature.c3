module clenshaw_curtis_quadrature;

extern fn double cos(double angle);

const usz MAX_PARSEABLE_INPUT_LENGTH = 19;
const double PI_PINNED = 3.14159265358979323846264338327950288;

fn bool exact_integer(double value, long low, long high, long* decoded) {
    if (!(value == value) || value < (double)low || value > (double)high || (double)(long)value != value) return false;
    *decoded = (long)value;
    return true;
}

fn double compute(long n, double* values) {
    double result = 0.0;
    for (long k=0; k<=n; k++) {
        double inner = 0.0;
        for (long j=1; j<=n/2; j++) {
            double bj = j == n/2 ? 1.0 : 2.0;
            double denominator = (double)(4*j*j-1);
            double angle = (((2.0*(double)j)*(double)k)*PI_PINNED)/(double)n;
            double term = (bj/denominator)*cos(angle);
            inner += term;
        }
        double gk = (k == 0 || k == n) ? 1.0 : 2.0;
        double weight = (gk/(double)n)*(1.0-inner);
        result += weight*values[k+1];
    }
    return result;
}

fn long clenshaw_curtis_quadrature(double* input, usz input_length,
                                  double* output, usz output_capacity)
    @export("clenshaw_curtis_quadrature") {
    if (input == null || input_length < 4 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    long n;
    if (!exact_integer(input[0],2,16,&n) || n%2 != 0 || input_length != (usz)(n+2)) return -1L;
    for (usz i=1; i<input_length; i++)
        if (!(input[i] == input[i]) || input[i] > 1000.0 || input[i] < -1000.0) return -1L;
    if (output == null || output_capacity < 1) return -2L;
    double value = compute(n,input);
    if (!(value == value) || value > 1e308 || value < -1e308) return -1L;
    output[0] = value;
    return 1L;
}
