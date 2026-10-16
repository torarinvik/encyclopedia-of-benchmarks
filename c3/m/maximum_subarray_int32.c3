module maximum_subarray_int32;

const usz MAX_LENGTH = 1024;
const long MAX_ABS_VALUE = 1000000;

fn long maximum_subarray_int32(long* values, usz length) @export("maximum_subarray_int32") {
    if (values == null || length == 0 || length > MAX_LENGTH) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -MAX_ABS_VALUE || values[index] > MAX_ABS_VALUE) return -1;
    }
    long current = values[0];
    long best = current;
    for (usz index = 1; index < length; index++) {
        current = current > 0 ? current + values[index] : values[index];
        if (current > best) best = current;
    }
    return best;
}
