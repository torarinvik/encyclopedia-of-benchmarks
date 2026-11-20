module goodstein_sequence_bounded_prefix;

const long MAX_INPUT_WORDS = 3;
const long MAX_START = 4;
const long MAX_TRANSITIONS = 16;
const usz MAX_TERMS = 17;

fn long small_power(long base, long exponent) {
    long result = 1;
    for (long index = 0; index < exponent; index++) result *= base;
    return result;
}

fn long rebase_hereditary(long value, long base, long raised_base) {
    if (value == 0) return 0;
    long result = 0;
    long place = 1;
    long exponent = 0;
    while (place <= value) {
        long digit = (value / place) % base;
        if (digit != 0) {
            long raised_exponent = rebase_hereditary(exponent, base, raised_base);
            result += digit * small_power(raised_base, raised_exponent);
        }
        place *= base;
        exponent++;
    }
    return result;
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long goodstein_sequence_bounded_prefix(long *input, usz length, char *output,
        usz capacity) @export("goodstein_sequence_bounded_prefix") {
    if (input == null || length < 1 || length > MAX_INPUT_WORDS || length != 2) return -1;
    long start = input[0];
    long transitions = input[1];
    if (start < 0 || start > MAX_START || transitions < 0 || transitions > MAX_TRANSITIONS) return -1;

    long[MAX_TERMS] terms = {0};
    usz count = 1;
    terms[0] = start;
    long current = start;
    long base = 2;
    for (long step = 0; step < transitions && current != 0; step++) {
        current = rebase_hereditary(current, base, base + 1) - 1;
        base++;
        terms[count] = current;
        count++;
    }

    usz output_bytes = (count + 1) * 8;
    if (output == null || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (long)count);
    for (usz index = 0; index < count; index++)
        store_i64_le(output, (index + 1) * 8, terms[index]);
    return (long)output_bytes;
}
