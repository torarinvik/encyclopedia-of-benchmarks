module momentum_sgd;

const double MAX_FINITE = 1.7976931348623157e308;
const usz MAX_PARSEABLE_INPUT_LENGTH = 270;
const usz MAX_VALID_INPUT_LENGTH = 269;
const usz MAX_GROUP_COUNT = 8;
const usz MAX_PARAMETER_COUNT = 16;
const usz MAX_GROUP_VECTOR_ELEMENTS = 32;
const usz MAX_CALL_COUNT = 8;

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn long momentum_sgd(double* input, usz input_length, double* output, usz output_capacity)
    @export("momentum_sgd")
{
    if (input == null || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) {
        if (!finite_value(input[i])) return -1;
    }

    double group_count_value = input[0];
    double parameter_count_value = input[1];
    double call_count_value = input[2];
    if (group_count_value < 1.0 || group_count_value > (double)MAX_GROUP_COUNT ||
        parameter_count_value < 1.0 || parameter_count_value > (double)MAX_PARAMETER_COUNT ||
        call_count_value < 1.0 || call_count_value > (double)MAX_CALL_COUNT) return -1;

    long group_count_long = (long)group_count_value;
    long parameter_count_long = (long)parameter_count_value;
    long call_count_long = (long)call_count_value;
    if (group_count_value != (double)group_count_long ||
        parameter_count_value != (double)parameter_count_long ||
        call_count_value != (double)call_count_long) return -1;
    usz group_count = (usz)group_count_long;
    usz parameter_count = (usz)parameter_count_long;
    usz call_count = (usz)call_count_long;
    if (group_count * parameter_count > MAX_GROUP_VECTOR_ELEMENTS ||
        call_count < group_count) return -1;

    usz expected_length = 5 + call_count * (1 + 2 * parameter_count);
    if (input_length != expected_length || input_length > MAX_VALID_INPUT_LENGTH) return -1;

    double learning_rate = input[3];
    double momentum = input[4];
    if (learning_rate < 1e-6 || learning_rate > 1.0 ||
        momentum < 0.0 || momentum > 0.99) return -1;

    bool[MAX_GROUP_COUNT] seen = {false};
    usz cursor = 5;
    for (usz call = 0; call < call_count; call++) {
        double id_value = input[cursor++];
        if (id_value < 0.0 || id_value >= (double)group_count) return -1;
        long param_id_long = (long)id_value;
        if (id_value != (double)param_id_long) return -1;
        usz param_id = (usz)param_id_long;
        seen[param_id] = true;

        for (usz i = 0; i < parameter_count; i++) {
            double parameter = input[cursor++];
            if (parameter < -1000.0 || parameter > 1000.0) return -1;
        }
        for (usz i = 0; i < parameter_count; i++) {
            double gradient = input[cursor++];
            if (gradient < -1000.0 || gradient > 1000.0) return -1;
        }
    }
    for (usz id = 0; id < group_count; id++) {
        if (!seen[id]) return -1;
    }

    usz group_elements = group_count * parameter_count;
    usz output_elements = 2 * group_elements;
    if (output == null || output_capacity < output_elements) return -2;

    double[MAX_GROUP_VECTOR_ELEMENTS] velocity = {0.0};
    double[MAX_GROUP_VECTOR_ELEMENTS] last_params = {0.0};

    cursor = 5;
    for (usz call = 0; call < call_count; call++) {
        usz param_id = (usz)(long)input[cursor++];
        usz group_offset = param_id * parameter_count;
        double[MAX_PARAMETER_COUNT] event_params;
        for (usz i = 0; i < parameter_count; i++) event_params[i] = input[cursor++];

        for (usz i = 0; i < parameter_count; i++) {
            usz index = group_offset + i;
            double gradient = input[cursor++];
            double previous_term = rounded_multiply(momentum, velocity[index]);
            double gradient_term = rounded_multiply(learning_rate, gradient);
            velocity[index] = rounded_subtract(previous_term, gradient_term);
            last_params[index] = rounded_add(event_params[i], velocity[index]);
        }
    }

    for (usz i = 0; i < group_elements; i++) {
        output[i] = last_params[i];
        output[group_elements + i] = velocity[i];
    }
    return (long)output_elements;
}
