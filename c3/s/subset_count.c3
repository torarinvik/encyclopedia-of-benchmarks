module subset_count;

const long MAX_COUNT = 30;
const long MAX_TARGET = 64;
const long MAX_VALUE = 64;
const usz MAX_INPUT_LENGTH = 33;
const long INVALID_RESULT = -1;

fn long subset_count(long* values, usz length) @export("subset_count") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;

    long count_value = values[0];
    long target = values[1];
    if (count_value < 1 || count_value > MAX_COUNT || target < 0 || target > MAX_TARGET ||
        length != (usz)count_value + 2) return INVALID_RESULT;

    for (long index = 0; index < count_value; index++) {
        long value = values[(usz)index + 2];
        if (value < 0 || value > MAX_VALUE) return INVALID_RESULT;
    }

    long[65] previous = {0};
    previous[0] = 1;
    if (values[2] <= target) previous[(usz)values[2]] = 1;

    for (long index = 1; index < count_value; index++) {
        long[65] current = {0};
        current[0] = 1;
        for (long amount = 1; amount <= target; amount++) {
            long not_taken = previous[(usz)amount];
            long value = values[(usz)index + 2];
            long taken = value <= amount ? previous[(usz)(amount - value)] : 0;
            current[(usz)amount] = not_taken + taken;
        }
        for (long amount = 0; amount <= target; amount++) {
            previous[(usz)amount] = current[(usz)amount];
        }
    }
    return previous[(usz)target];
}
