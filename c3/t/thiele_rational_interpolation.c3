module thiele_rational_interpolation;

const usz MAX_N = 6;
const usz MAX_INPUT = 15;
const double MAX_FINITE = 1.7976931348623157e308;
const double GRID_DENOMINATOR = 18014398509481984.0;
const double MIN_NODE_SEPARATION = 0.0625;
const double MIN_MAGNITUDE = 0.03125;
const double MAX_MAGNITUDE = 64.0;
const double BOUNDARY_GUARD = 0.00000000023283064365386963;

fn bool guarded_magnitude(double value) {
    double lower = MIN_MAGNITUDE + BOUNDARY_GUARD;
    double upper = MAX_MAGNITUDE - BOUNDARY_GUARD;
    return (value > lower && value < upper) || (value < -lower && value > -upper);
}

fn bool below_magnitude_cap(double value) {
    double cap = MAX_MAGNITUDE - BOUNDARY_GUARD;
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE && value > -cap && value < cap;
}

fn bool finite_in_range(double value) {
    if (!(value == value && value <= MAX_FINITE && value >= -MAX_FINITE && value >= -8.0 && value <= 8.0)) return false;
    double scaled = value * GRID_DENOMINATOR;
    return (double)(long)scaled == scaled;
}

fn long thiele_rational_interpolation(double* input, usz input_length, double* output, usz output_capacity)
        @export("thiele_rational_interpolation") {
    if (input == null || input_length < 4 || input_length > MAX_INPUT) return -1;
    double n_value = input[0];
    if (!finite_in_range(n_value) || (double)(long)n_value != n_value || n_value < 1.0 || n_value > 6.0) return -1;
    usz n = (usz)n_value;
    if (input_length != 2 + 2 * n) return -1;

    double[6] x = zeroed;
    double[6] y = zeroed;
    double[36] difference = zeroed;
    for (usz i = 0; i < n; i++) {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (!finite_in_range(x[i]) || !finite_in_range(y[i])) return -1;
        for (usz j = 0; j < i; j++)
            if (x[i] == x[j] || x[i] - x[j] < MIN_NODE_SEPARATION && x[i] - x[j] > -MIN_NODE_SEPARATION) return -1;
        difference[i] = y[i];
    }
    double query = input[input_length - 1];
    if (!finite_in_range(query)) return -1;

    for (usz order = 1; order < n; order++) {
        for (usz endpoint = order; endpoint < n; endpoint++) {
            double denominator = difference[(order - 1) * 6 + order - 1] - difference[(order - 1) * 6 + endpoint];
            if (!guarded_magnitude(denominator) || denominator != denominator || denominator > MAX_FINITE || denominator < -MAX_FINITE) return -1;
            double value = (x[order - 1] - x[endpoint]) / denominator;
            if (!below_magnitude_cap(value)) return -1;
            difference[order * 6 + endpoint] = value;
        }
        if (!guarded_magnitude(difference[order * 6 + order])) return -1;
    }

    double result = 0.0;
    bool at_node = false;
    for (usz i = 0; i < n; i++) {
        if (query == x[i]) { result = y[i]; at_node = true; break; }
    }
    if (!at_node && n == 1) result = y[0];
    if (!at_node && n > 1) {
        double tail = difference[(n - 1) * 6 + n - 1];
        usz order = n - 1;
        while (order > 1) {
            order--;
            if (!guarded_magnitude(tail) || tail != tail || tail > MAX_FINITE || tail < -MAX_FINITE) return -1;
            tail = difference[order * 6 + order] + (query - x[order]) / tail;
            if (!below_magnitude_cap(tail)) return -1;
        }
        if (!guarded_magnitude(tail) || tail != tail || tail > MAX_FINITE || tail < -MAX_FINITE) return -1;
        result = y[0] + (query - x[0]) / tail;
    }
    if (!below_magnitude_cap(result)) return -1;
    if (output == null || output_capacity < 1) return -2;
    output[0] = result;
    return 1;
}
