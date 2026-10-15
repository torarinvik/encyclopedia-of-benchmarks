module check_vowels;

const usz MAX_LENGTH = 4096;

// Return whether any lowercase ASCII vowel appears in the input.
fn long check_vowels(long* values, usz length) @export("check_vowels") {
    if (length > MAX_LENGTH || (length > 0 && values == null)) return -1L;
    for (usz i = 0; i < length; i++) if (values[i] < 97L || values[i] > 122L) return -1L;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value == 97L || value == 101L || value == 105L || value == 111L || value == 117L) return 1L;
    }
    return 0L;
}
