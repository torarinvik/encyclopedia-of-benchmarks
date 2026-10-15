module collatz_sequence;

const long MAX_START = 1000000;

fn long next_term(long value) {
    return value % 2 == 0 ? value / 2 : 3 * value + 1;
}

fn usz store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits /= 256;
    }
    return offset + 8;
}

fn long collatz_sequence(long* input, usz length, char* output, usz output_capacity)
        @export("collatz_sequence") {
    if (length != 1 || input[0] < 1 || input[0] > MAX_START) return -1;
    long current = input[0];
    usz term_count = 1;
    while (current != 1) {
        current = next_term(current);
        term_count++;
    }
    usz required = term_count * 8;
    if (output_capacity < required) return -2;
    current = input[0];
    usz written = 0;
    while (true) {
        written = store_i64_le(output, written, current);
        if (current == 1) break;
        current = next_term(current);
    }
    return (long)written;
}
