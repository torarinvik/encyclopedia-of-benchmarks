module first_unique_character;

const usz MAX_LENGTH = 1024;
const long INVALID_RESULT = -2;

// Return the first lowercase ASCII letter whose frequency is one.
fn long first_unique_character(long* values, usz length) @export("first_unique_character") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return INVALID_RESULT;
    usz[26] counts;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 97 || values[i] > 122) return INVALID_RESULT;
        counts[(usz)(values[i] - 97)]++;
    }
    for (usz i = 0; i < length; i++) {
        if (counts[(usz)(values[i] - 97)] == 1) return (long)i;
    }
    return -1;
}
