module maximum_circular_subarray;

const usz MAX_INPUT_LENGTH = 64;
const long INVALID_RESULT = -9223372036854775807 - 1;

fn long maximum_circular_subarray(long* values, usz length) @export("maximum_circular_subarray") {
    if (values == null || length == 0 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -1000000 || values[index] > 1000000) return INVALID_RESULT;
    }

    long total = values[0];
    long current_max = values[0], max_so_far = values[0];
    long current_min = values[0], min_so_far = values[0];
    for (usz index = 1; index < length; index++) {
        long value = values[index];
        current_max = current_max + value > value ? current_max + value : value;
        max_so_far = max_so_far > current_max ? max_so_far : current_max;
        current_min = current_min + value < value ? current_min + value : value;
        min_so_far = min_so_far < current_min ? min_so_far : current_min;
        total += value;
    }
    if (min_so_far == total) return max_so_far;
    return max_so_far > total - min_so_far ? max_so_far : total - min_so_far;
}
