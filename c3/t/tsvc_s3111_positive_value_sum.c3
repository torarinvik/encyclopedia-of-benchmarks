module tsvc_s3111_positive_value_sum;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + MAX_N;
const long MAX_VALUE = 1000000;

fn long tsvc_s3111_positive_value_sum(long* input, usz length)
        @export("tsvc_s3111_positive_value_sum") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 0 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + n) return -1;

    long sum = 0;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        if (value > 0) sum += value;
    }
    return sum;
}
