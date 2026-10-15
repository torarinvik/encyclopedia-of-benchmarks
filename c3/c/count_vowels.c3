module count_vowels;

const usz MAX_LENGTH = 4096;
const long INVALID_RESULT = -2;

// Count ASCII vowels in a bounded string represented by byte values.
fn long count_vowels(long* values, usz length) @export("count_vowels") {
    if (length == 0 || length > MAX_LENGTH || values == null) return INVALID_RESULT;
    if (length == 1 && values[0] == 48) return INVALID_RESULT;
    long count = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 0 || value > 127 || value == 44) return INVALID_RESULT;
        if (value == 97 || value == 101 || value == 105 || value == 111 || value == 117 ||
            value == 65 || value == 69 || value == 73 || value == 79 || value == 85) count++;
    }
    return count;
}
