module pushdown_automaton;

const long MAX_BYTE_LENGTH = 256;
const usz MAX_INPUT_LENGTH = 257;

// Recognize the bounded language (1|2)^n 0^n with a pushdown-style counter.
fn long pushdown_automaton(long* values, usz length) @export("pushdown_automaton") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long byte_length = values[0];
    if (byte_length < 0 || byte_length > MAX_BYTE_LENGTH) return -1;
    usz count = (usz)byte_length;
    if (length != count + 1) return -1;

    for (usz index = 0; index < count; index++) {
        long byte = values[index + 1];
        if (byte < 48 || byte > 50) return -1;
    }
    if (count == 0 || count % 2 != 0) return 0;

    usz half = count / 2;
    for (usz index = 0; index < half; index++) {
        if (values[index + 1] != 49 && values[index + 1] != 50) return 0;
    }
    for (usz index = half; index < count; index++) {
        if (values[index + 1] != 48) return 0;
    }
    return 1;
}
