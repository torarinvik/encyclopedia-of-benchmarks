module sumset;

const MIN_SUM = -2000;
const MAX_SUM = 2000;
const SUM_COUNT = 4001;
const MAX_SET_SIZE = 64;

fn usz decimal_width(long value) {
    usz width = 1;
    if (value < 0) { value = -value; width++; }
    while (value >= 10) { value /= 10; width++; }
    return width;
}

fn usz append_signed_decimal(char* output, usz position, long value) {
    if (value < 0) { output[position++] = '-'; value = -value; }
    char[20] digits; usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value != 0);
    while (count > 0) { count--; output[position++] = digits[count]; }
    return position;
}

fn long sumset(long* values, usz length, char* output, usz output_capacity) @export("sumset") {
    if (values == null || length < 2) return -1;
    long count_a = values[0], count_b = values[1];
    if (count_a < 0 || count_a > MAX_SET_SIZE || count_b < 0 || count_b > MAX_SET_SIZE ||
        length != 2 + (usz)count_a + (usz)count_b) return -1;
    bool[SUM_COUNT] present = {false};
    for (usz index_a = 0; index_a < (usz)count_a; index_a++) {
        long left = values[2 + index_a];
        if (left < -1000 || left > 1000) return -1;
    }
    for (usz index_b = 0; index_b < (usz)count_b; index_b++) {
        long right = values[2 + (usz)count_a + index_b];
        if (right < -1000 || right > 1000) return -1;
    }
    for (usz index_a = 0; index_a < (usz)count_a; index_a++) {
        long left = values[2 + index_a];
        for (usz index_b = 0; index_b < (usz)count_b; index_b++) {
            long right = values[2 + (usz)count_a + index_b];
            long sum = left + right;
            present[sum - MIN_SUM] = true;
        }
    }
    usz needed = 0;
    for (long sum = MIN_SUM; sum <= MAX_SUM; sum++) {
        if (present[sum - MIN_SUM]) needed += decimal_width(sum) + 1;
    }
    if (needed == 0) return 0;
    if (output == null || output_capacity < needed) return -2;
    usz position = 0;
    for (long sum = MIN_SUM; sum <= MAX_SUM; sum++) {
        if (!present[sum - MIN_SUM]) continue;
        position = append_signed_decimal(output, position, sum);
        output[position++] = '\n';
    }
    return (long)position;
}
