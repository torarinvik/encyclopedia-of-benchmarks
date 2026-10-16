module count_homogenous;

const usz MAX_TEXT_BYTES = 4096;

// Count contiguous runs of equal ASCII bytes.
fn long count_homogenous(long* input, usz length) @export("count_homogenous") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > (long)MAX_TEXT_BYTES) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    for (usz i = 0; i < count; i++) {
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    }
    if (count == 0) return 0;
    usz runs = 1;
    for (usz i = 2; i <= count; i++) {
        if (input[i] != input[i - 1]) runs++;
    }
    return (long)runs;
}
