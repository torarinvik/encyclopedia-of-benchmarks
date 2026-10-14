module ceil;

const usz MAX_VALUES = 256;
const usz MAX_INPUT_VALUES = 1 + 2 * MAX_VALUES;
const long NUMERATOR_LIMIT = 1000000000000;
const long DENOMINATOR_LIMIT = 1000000;
const long RESULT_OFFSET = 1000000000001;

fn long ceil_division(long numerator, long denominator) {
    if (numerator >= 0) return numerator / denominator + (long)(numerator % denominator != 0);
    return -((-numerator) / denominator);
}

fn long ceil_benchmark(long* values, usz length) @export("ceil_benchmark") {
    if (length < 1 || length > MAX_INPUT_VALUES) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > (long)MAX_VALUES) return -1;
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) return -1;
    for (usz i = 0; i < count; i++) {
        long numerator = values[1 + 2 * i];
        long denominator = values[2 + 2 * i];
        if (numerator < -NUMERATOR_LIMIT || numerator > NUMERATOR_LIMIT ||
            denominator < 1 || denominator > DENOMINATOR_LIMIT) return -1;
    }
    long checksum = 0;
    for (usz i = 0; i < count; i++) {
        long result = ceil_division(values[1 + 2 * i], values[2 + 2 * i]);
        checksum += (long)(i + 1) * (result + RESULT_OFFSET);
    }
    return checksum;
}
