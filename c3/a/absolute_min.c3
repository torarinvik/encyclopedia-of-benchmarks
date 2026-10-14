module absolute_min;

const usz MAX_VALUES = 256;
const usz MAX_INPUT_VALUES = MAX_VALUES + 1;
const long VALUE_LIMIT = 1000000000;

fn long magnitude(long value) { return value < 0 ? -value : value; }

fn long select_absolute(long* values, usz length, bool maximum) {
    if (length < 2 || length > MAX_INPUT_VALUES) return -1;
    long count_value = values[0];
    if (count_value < 1 || count_value > (long)MAX_VALUES || length != (usz)count_value + 1) return -1;
    for (usz index = 1; index < length; index++) {
        if (values[index] < -VALUE_LIMIT || values[index] > VALUE_LIMIT) return -1;
    }
    long best = values[1];
    for (usz index = 2; index < length; index++) {
        long candidate = values[index];
        if (maximum ? (magnitude(candidate) > magnitude(best) || (magnitude(candidate) == magnitude(best) && candidate > best)) : (magnitude(candidate) < magnitude(best) || (magnitude(candidate) == magnitude(best) && candidate < best))) best = candidate;
    }
    return best;
}

fn long absolute_min_benchmark(long* values, usz length) @export("absolute_min_benchmark") {
    return select_absolute(values, length, false);
}
