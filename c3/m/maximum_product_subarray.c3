module maximum_product_subarray;

const usz MAX_INPUT_LENGTH = 9;
const long INVALID_RESULT = -9223372036854775807 - 1;

fn long maximum_product_subarray(long* values, usz length) @export("maximum_product_subarray") {
    if (values == null || length == 0 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -10 || values[index] > 10) return INVALID_RESULT;
    }

    long current_max = values[0], current_min = values[0], best = values[0];
    for (usz index = 1; index < length; index++) {
        long value = values[index];
        long prior_max = current_max, prior_min = current_min;
        long from_max = prior_max * value, from_min = prior_min * value;
        current_max = value > from_max ? (value > from_min ? value : from_min)
                                       : (from_max > from_min ? from_max : from_min);
        current_min = value < from_max ? (value < from_min ? value : from_min)
                                       : (from_max < from_min ? from_max : from_min);
        best = best > current_max ? best : current_max;
    }
    return best;
}
