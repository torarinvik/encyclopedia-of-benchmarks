module tsvc_s331_last_negative_index;
const usz MAX_N = 256;
const long MAX_VALUE = 1000000;
fn long tsvc_s331_last_negative_index(long* input, usz length) @export("tsvc_s331_last_negative_index") {
    if (input == null || length < 2 || length > 1 + MAX_N) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || length != 1 + (usz)input[0]) return -1;
    long result = 0;
    for (usz i = 0; i < (usz)input[0]; i += 1) {
        long value = input[1 + i];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        if (value < 0) result = (long)i + 1;
    }
    return result;
}
