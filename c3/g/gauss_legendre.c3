module gauss_legendre;

extern fn double sqrt(double value);

const double MAX_ITERATIONS = 8.0;
const double INVALID_RESULT = -1.0e300;

fn double pi_after_iterations(int iterations) {
    double a = 1.0;
    double b = sqrt(0.5);
    double t = 0.25;
    double p = 1.0;
    for (int index = 0; index < iterations; index++) {
        double[4] values;
        values[0] = (a + b) / 2.0;
        values[1] = sqrt(a * b);
        double difference = a - values[0];
        values[2] = t - p * difference * difference;
        values[3] = 2.0 * p;
        a = values[0];
        b = values[1];
        t = values[2];
        p = values[3];
    }
    double sum = a + b;
    return sum * sum / (4.0 * t);
}

fn double gauss_legendre(double iterations_value) @export("gauss_legendre") {
    if (!(iterations_value >= 0.0 && iterations_value <= MAX_ITERATIONS)
            || iterations_value != (double)(int)iterations_value) return INVALID_RESULT;
    return pi_after_iterations((int)iterations_value);
}
