module booths_algorithm;

fn long booths_algorithm(long* values, usz length, char* output, usz capacity) @export("booths_algorithm") {
    if (values == null && length != 0) return -1;
    if (length == 0 || length > 256) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    if (output == null || capacity < length) return -2;

    long[512] failure;
    for (usz index = 0; index < 2 * length; index++) failure[index] = -1;
    usz start = 0;
    for (usz j = 1; j < 2 * length; j++) {
        long current = values[j % length];
        long matched = failure[j - start - 1];
        while (matched != -1 && current != values[(start + (usz)matched + 1) % length]) {
            if (current < values[(start + (usz)matched + 1) % length]) start = j - (usz)matched - 1;
            matched = failure[(usz)matched];
        }
        if (matched == -1 && current != values[start % length]) {
            if (current < values[start % length]) start = j;
            failure[j - start] = -1;
        } else {
            failure[j - start] = matched + 1;
        }
    }

    for (usz index = 0; index < length; index++) output[index] = (char)values[(start + index) % length];
    return (long)length;
}
