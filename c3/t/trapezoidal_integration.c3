module trapezoidal_integration;

const long SCALE = 1000000;
const long MAX_ENDPOINT_MICRO = 1000000;
const long MAX_STEPS = 10000;
const double INVALID_RESULT = -1.0e300;

fn double sample_value(long function_id, double x) {
    if (function_id == 0) return x * x;
    return x * x * x;
}

fn double trapezoidal_integration_impl(long* values, usz length) {
    if (values == null || length != 4) return INVALID_RESULT;
    long start_micro = values[0], end_micro = values[1];
    long steps = values[2], function_id = values[3];
    if (start_micro < -MAX_ENDPOINT_MICRO || start_micro > MAX_ENDPOINT_MICRO ||
        end_micro < -MAX_ENDPOINT_MICRO || end_micro > MAX_ENDPOINT_MICRO ||
        steps < 1 || steps > MAX_STEPS || function_id < 0 || function_id > 1) return INVALID_RESULT;
    double start = (double)start_micro / (double)SCALE;
    double end = (double)end_micro / (double)SCALE;
    double delta = (end - start) / (double)steps;
    double total = 0.0;
    for (long index = 0; index < steps; index += 1) {
        double left = start + delta * (double)index;
        double right = left + delta;
        double midpoint = (sample_value(function_id, left) + sample_value(function_id, right)) * 0.5;
        total += midpoint * delta;
    }
    return total;
}

fn double trapezoidal_integration(long* values, usz length) @export("trapezoidal_integration") {
    return trapezoidal_integration_impl(values, length);
}
