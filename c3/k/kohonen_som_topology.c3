module kohonen_som_topology;

extern fn double exp(double value);
extern fn double sqrt(double value);

const usz MAX_MAP_SIZE = 4;
const usz MAX_FEATURE_COUNT = 3;
const usz MAX_PARSEABLE_INPUT_LENGTH = 56;
const usz MAX_OUTPUT_ELEMENTS = 49;

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

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn long kohonen_som_topology(double* input, usz input_length, double* output, usz output_capacity)
    @export("kohonen_som_topology") {
    if (input == null || input_length < 4 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;

    long map_size_value;
    long feature_count_value;
    long radius_value;
    long alpha_code_value;
    if (!exact_integer_in_range(input[0], 1, (long)MAX_MAP_SIZE, &map_size_value) ||
        !exact_integer_in_range(input[1], 1, (long)MAX_FEATURE_COUNT, &feature_count_value) ||
        !exact_integer_in_range(input[2], 0, 8, &radius_value) ||
        !exact_integer_in_range(input[3], 1, 16, &alpha_code_value)) return -1L;

    usz map_size = (usz)map_size_value;
    usz feature_count = (usz)feature_count_value;
    usz radius = (usz)radius_value;
    usz weight_count = map_size * map_size * feature_count;
    usz expected_length = 4 + feature_count + weight_count;
    if (input_length != expected_length) return -1L;

    double[MAX_FEATURE_COUNT] sample = zeroed;
    double[MAX_MAP_SIZE * MAX_MAP_SIZE * MAX_FEATURE_COUNT] weights = zeroed;
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

    double[MAX_MAP_SIZE * MAX_MAP_SIZE] distances = zeroed;
    for (usz x = 0; x < map_size; x++) {
        for (usz y = 0; y < map_size; y++) {
            double distance_squared = 0.0;
            for (usz feature = 0; feature < feature_count; feature++) {
                usz index = (x * map_size + y) * feature_count + feature;
                double difference = rounded_subtract(weights[index], sample[feature]);
                double squared = rounded_multiply(difference, difference);
                distance_squared = rounded_add(distance_squared, squared);
            }
            double distance = sqrt(distance_squared);
            if (!finite_value(distance)) return -1L;
            distances[x * map_size + y] = distance;
        }
    }

    usz best_x = 0;
    usz best_y = 0;
    double minimum_distance = distances[0];
    for (usz x = 0; x < map_size; x++) {
        for (usz y = 0; y < map_size; y++) {
            double distance = distances[x * map_size + y];
            if (distance < minimum_distance) {
                minimum_distance = distance;
                best_x = x;
                best_y = y;
            }
        }
    }

    usz from_x = 0;
    usz from_y = 0;
    if (best_x > radius) from_x = best_x - radius;
    if (best_y > radius) from_y = best_y - radius;
    usz candidate_to_x = best_x + radius + 1;
    usz candidate_to_y = best_y + radius + 1;
    usz to_x = candidate_to_x < map_size ? candidate_to_x : map_size;
    usz to_y = candidate_to_y < map_size ? candidate_to_y : map_size;
    double alpha = (double)alpha_code_value / 16.0;
    for (usz x = from_x; x < to_x; x++) {
        for (usz y = from_y; y < to_y; y++) {
            long dx = (long)best_x - (long)x;
            long dy = (long)best_y - (long)y;
            long grid_distance_squared = dx * dx + dy * dy;
            double two_alpha = rounded_multiply(2.0, alpha);
            double denominator = rounded_multiply(two_alpha, alpha);
            double exponent = rounded_divide(-(double)grid_distance_squared, denominator);
            double scale_factor = exp(exponent);
            if (!finite_value(scale_factor)) return -1L;
            double alpha_scale = rounded_multiply(alpha, scale_factor);

            for (usz feature = 0; feature < feature_count; feature++) {
                usz index = (x * map_size + y) * feature_count + feature;
                double difference = rounded_subtract(sample[feature], weights[index]);
                double adjustment = rounded_multiply(alpha_scale, difference);
                double value = rounded_add(weights[index], adjustment);
                if (!finite_value(value)) return -1L;
                weights[index] = value;
            }
        }
    }

    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    staged[0] = minimum_distance;
    for (usz index = 0; index < weight_count; index++) {
        if (!finite_value(weights[index])) return -1L;
        staged[index + 1] = weights[index];
    }
    usz output_length = weight_count + 1;
    if (output == null || output_capacity < output_length) return -2L;
    for (usz index = 0; index < output_length; index++) output[index] = staged[index];
    return (long)output_length;
}
