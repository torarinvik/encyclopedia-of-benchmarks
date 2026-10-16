module subarray_sum_equals_k;

const usz MAX_ITEMS = 512;
const usz TABLE_SIZE = 2048;
const long INVALID_RESULT = -9223372036854775807L - 1L;

fn usz slot_for(long value) {
    long magnitude = value < 0 ? -value : value;
    return (usz)(magnitude % (long)TABLE_SIZE);
}

fn long subarray_sum_equals_k(long* input, usz length) @export("subarray_sum_equals_k") {
    if (input == null || length < 2 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    long count_value = input[0];
    long target = input[1];
    if (count_value < 0 || count_value > (long)MAX_ITEMS ||
        target < -2147483648L || target > 2147483647L) return INVALID_RESULT;
    usz count = (usz)count_value;
    if (length != count + 2) return INVALID_RESULT;
    for (usz index = 0; index < count; index++) {
        if (input[index + 2] < -2147483648L || input[index + 2] > 2147483647L) return INVALID_RESULT;
    }

    long[TABLE_SIZE] keys = zeroed;
    long[TABLE_SIZE] frequencies = zeroed;
    frequencies[0] = 1;
    long prefix_sum = 0;
    long result = 0;
    for (usz index = 0; index < count; index++) {
        prefix_sum += input[index + 2];
        long required = prefix_sum - target;
        usz slot = slot_for(required);
        while (frequencies[slot] != 0 && keys[slot] != required) slot = (slot + 1) % TABLE_SIZE;
        result += frequencies[slot];

        slot = slot_for(prefix_sum);
        while (frequencies[slot] != 0 && keys[slot] != prefix_sum) slot = (slot + 1) % TABLE_SIZE;
        if (frequencies[slot] == 0) keys[slot] = prefix_sum;
        frequencies[slot] += 1;
    }
    return result;
}
