module maximum_subarray_allow_empty;

const usz MAX_LENGTH = 1024;

fn long maximum_subarray_allow_empty(long* values, usz length) @export("maximum_subarray_allow_empty") {
    if (length > MAX_LENGTH || (length > 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
    }
    long current = 0;
    long best = 0;
    for (usz index = 0; index < length; index++) {
        current += values[index];
        if (current < 0) current = 0;
        if (current > best) best = current;
    }
    return best;
}
