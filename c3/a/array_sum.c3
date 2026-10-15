module array_sum;

const long INVALID_RESULT = -1;

fn long array_sum(long* values, usz length) @export("array_sum") {
    if (values == null || length < 1) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 0 || count_value > 1024) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != count + 1) return INVALID_RESULT;
    long sum = 0;
    for (usz i = 0; i < count; i++) {
        long value = values[i + 1];
        if (value < 0 || value > 1000000000) return INVALID_RESULT;
        sum += value;
    }
    return sum;
}
