module poisson_dist;

extern fn double pow(double base, double exponent);
extern fn double exp(double value);

const long MAX_MILLI_VALUE = 100000;
const long MAX_SUCCESS_COUNT = 20;
const double INVALID_RESULT = -1.0e300;

fn double poisson_factorial(double x) {
    double factorial = x;
    for (long i = (long)x - 1; i > 0; i -= 1) factorial *= (double)i;
    if (factorial <= 0.0) factorial = 1.0;
    return factorial;
}

fn double poisson_point(double mean, long successes) {
    return (pow(mean, (double)successes) * exp(-mean)) / poisson_factorial((double)successes);
}

fn double poisson_dist(long* input, usz length) @export("poisson_dist") {
    if (input == null || length != 4) return INVALID_RESULT;
    long operation = input[0], first = input[1], second = input[2], third = input[3];
    if (operation == 0) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 1 || second > MAX_MILLI_VALUE || third != 0)
            return INVALID_RESULT;
        return ((double)first / 1000.0) / ((double)second / 1000.0);
    }
    if (operation == 1) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > MAX_MILLI_VALUE || third != 0)
            return INVALID_RESULT;
        return ((double)first / 1000.0) * ((double)second / 1000.0);
    }
    if (operation == 2) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > MAX_SUCCESS_COUNT || third != 0)
            return INVALID_RESULT;
        return poisson_point((double)first / 1000.0, second);
    }
    if (operation == 3) {
        if (first < 0 || first > MAX_MILLI_VALUE || second < 0 || second > third || third > MAX_SUCCESS_COUNT)
            return INVALID_RESULT;
        double mean = (double)first / 1000.0;
        double probability = 0.0;
        for (long successes = second; successes <= third; successes += 1)
            probability += poisson_point(mean, successes);
        return probability;
    }
    return INVALID_RESULT;
}
