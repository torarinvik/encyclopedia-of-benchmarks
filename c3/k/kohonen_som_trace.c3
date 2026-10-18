module kohonen_som_trace;

const usz MAX_NODE_COUNT = 8;
const usz MAX_FEATURE_COUNT = 4;
const usz MAX_RADIUS = 8;
const usz MIN_ALPHA_CODE = 1;
const usz MAX_ALPHA_CODE = 16;
const usz MAX_PARSEABLE_INPUT_LENGTH = 41;
const usz MAX_OUTPUT_ELEMENTS = 32;

fn bool finite_value(double value) {
    return value == value && value >= -1e308 && value <= 1e308;
}

fn bool exact_integer_in_range(double value, long minimum, long maximum, long* integer) {
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum) return false;
    long converted = (long)value;
    if ((double)converted != value) return false;
    *integer = converted;
    return true;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn long kohonen_som_trace(double* input, usz input_length, double* output, usz output_capacity)
    @export("kohonen_som_trace") {
    if (input == null || input_length < 4 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;

    long node_count_value;
    long feature_count_value;
    long radius_value;
    long alpha_code_value;
    if (!exact_integer_in_range(input[0], 1, (long)MAX_NODE_COUNT, &node_count_value) ||
        !exact_integer_in_range(input[1], 1, (long)MAX_FEATURE_COUNT, &feature_count_value) ||
        !exact_integer_in_range(input[2], 0, (long)MAX_RADIUS, &radius_value) ||
        !exact_integer_in_range(input[3], (long)MIN_ALPHA_CODE, (long)MAX_ALPHA_CODE, &alpha_code_value))
        return -1L;

    usz node_count = (usz)node_count_value;
    usz feature_count = (usz)feature_count_value;
    usz radius = (usz)radius_value;
    usz weight_count = node_count * feature_count;
    usz expected_length = 4 + feature_count + weight_count;
    if (input_length != expected_length) return -1L;

    double[MAX_FEATURE_COUNT] sample = zeroed;
    double[MAX_OUTPUT_ELEMENTS] weights = zeroed;
    for (usz feature = 0; feature < feature_count; feature++) {
        long integer;
        if (!exact_integer_in_range(input[4 + feature], -8, 8, &integer)) return -1L;
        sample[feature] = (double)integer;
    }
    for (usz index = 0; index < weight_count; index++) {
        long integer;
        if (!exact_integer_in_range(input[4 + feature_count + index], -8, 8, &integer)) return -1L;
        weights[index] = (double)integer;
    }

    double[MAX_NODE_COUNT] distances = zeroed;
    for (usz node = 0; node < node_count; node++) {
        double distance = 0.0;
        for (usz feature = 0; feature < feature_count; feature++) {
            double difference = rounded_subtract(weights[node * feature_count + feature], sample[feature]);
            double squared = rounded_multiply(difference, difference);
            distance = rounded_add(distance, squared);
        }
        if (!finite_value(distance)) return -1L;
        distances[node] = distance;
    }

    usz best_node = 0;
    for (usz node = 1; node < node_count; node++) {
        if (distances[node] < distances[best_node]) best_node = node;
    }

    usz from_node = 0;
    if (best_node > radius) from_node = best_node - radius;
    usz candidate_to_node = best_node + radius + 1;
    usz to_node = node_count;
    if (candidate_to_node < node_count) to_node = candidate_to_node;
    double alpha = (double)alpha_code_value / 16.0;
    for (usz node = from_node; node < to_node; node++) {
        for (usz feature = 0; feature < feature_count; feature++) {
            usz index = node * feature_count + feature;
            double difference = rounded_subtract(sample[feature], weights[index]);
            double adjustment = rounded_multiply(alpha, difference);
            double value = rounded_add(weights[index], adjustment);
            if (!finite_value(value)) return -1L;
            weights[index] = value;
        }
    }

    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    for (usz index = 0; index < weight_count; index++) staged[index] = weights[index];
    if (output == null || output_capacity < weight_count) return -2L;
    for (usz index = 0; index < weight_count; index++) output[index] = staged[index];
    return (long)weight_count;
}
