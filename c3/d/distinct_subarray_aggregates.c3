module distinct_subarray_aggregates;

const usz MAX_N = 64;
const usz MAX_INPUT = 67;
const usz MAX_SEGMENTS = 65;

fn long gcd_nonnegative(long a, long b) {
    while (b != 0) {
        long remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

fn long combine_value(long mode, long a, long b) {
    if (mode == 0) return gcd_nonnegative(a, b);
    if (mode == 1) return a | b;
    return a & b;
}

fn long distinct_subarray_aggregates(long* input, usz length) @export("distinct_subarray_aggregates") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long mode = input[0], n0 = input[1];
    if (mode < 0 || mode > 2 || n0 < 0 || n0 > 64) return -1;
    usz n = (usz)n0;
    if (length != 2 + n) return -1;

    long[MAX_SEGMENTS] segment_value, segment_left, segment_right;
    usz segment_count = 0;
    long aggregate_sum = 0, suffix_distinct_count = 0;
    for (usz right = 0; right < n; right++) {
        long value = input[2 + right];
        if (value < 0 || value > 255) return -1;
        for (usz j = 0; j < segment_count; j++) {
            segment_value[j] = combine_value(mode, segment_value[j], value);
        }
        segment_value[segment_count] = value;
        segment_left[segment_count] = (long)right;
        segment_right[segment_count] = (long)right;
        segment_count++;

        usz write = 0;
        for (usz read = 0; read < segment_count; read++) {
            if (write > 0 && segment_value[read] == segment_value[write - 1]) {
                segment_right[write - 1] = segment_right[read];
            } else {
                segment_value[write] = segment_value[read];
                segment_left[write] = segment_left[read];
                segment_right[write] = segment_right[read];
                write++;
            }
        }
        segment_count = write;
        suffix_distinct_count += (long)segment_count;
        for (usz j = 0; j < segment_count; j++) {
            aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1);
        }
    }
    return aggregate_sum * 1024 + suffix_distinct_count;
}
