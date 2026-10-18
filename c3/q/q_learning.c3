module q_learning;

const usz MAX_NEXT_ACTIONS = 4;
const usz MAX_VALID_INPUT_LENGTH = 10;
const usz MAX_PARSEABLE_INPUT_LENGTH = 11;

fn bool finite_value(double value) {
    return value == value && value >= -1e308 && value <= 1e308;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn bool exact_action_count(double value, usz* count) {
    if (!finite_value(value) || value < 0.0 || value > (double)MAX_NEXT_ACTIONS) return false;
    long converted = (long)value;
    if ((double)converted != value) return false;
    *count = (usz)converted;
    return true;
}

fn long q_learning_update(double* input, usz input_length, double* output, usz output_capacity)
    @export("q_learning_update") {
    if (input == null || input_length < 6 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < input_length; index++)
        if (!finite_value(input[index])) return -1L;

    if (input[0] != 0.0 && input[0] != 1.0) return -1L;
    double alpha = input[1];
    double gamma = input[2];
    double reward = input[3];
    double old_q = input[4];
    if (alpha < 0.0 || alpha > 1.0 || gamma < 0.0 || gamma > 1.0 ||
        reward < -100.0 || reward > 100.0 || old_q < -100.0 || old_q > 100.0) return -1L;

    usz next_action_count;
    if (!exact_action_count(input[5], &next_action_count) ||
        input_length != 6 + next_action_count || input_length > MAX_VALID_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < next_action_count; index++)
        if (input[6 + index] < -100.0 || input[6 + index] > 100.0) return -1L;

    double max_q_next = 0.0;
    if (input[0] == 0.0 && next_action_count > 0) {
        max_q_next = input[6];
        for (usz index = 1; index < next_action_count; index++)
            if (input[6 + index] > max_q_next) max_q_next = input[6 + index];
    }

    double old_weight = rounded_subtract(1.0, alpha);
    double old_contribution = rounded_multiply(old_weight, old_q);
    double discounted_next = rounded_multiply(gamma, max_q_next);
    double target = rounded_add(reward, discounted_next);
    double new_contribution = rounded_multiply(alpha, target);
    double updated = rounded_add(old_contribution, new_contribution);
    if (!finite_value(updated)) return -1L;

    if (output == null || output_capacity < 1) return -2L;
    output[0] = updated;
    return 1L;
}
