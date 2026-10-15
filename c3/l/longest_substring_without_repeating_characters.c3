module longest_substr_without_repeat;

const usz MAX_LENGTH = 1024;
const usz ALPHABET_SIZE = 95;
const long INVALID_RESULT = -2;

// Return the longest printable-ASCII substring with no repeated byte.
fn long longest_substring_without_repeating_characters(long* values, usz length) @export("longest_substring_without_repeating_characters") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return INVALID_RESULT;
    long[ALPHABET_SIZE] last_seen;
    for (usz slot = 0; slot < ALPHABET_SIZE; slot++) last_seen[slot] = -1;
    usz window_start = 0;
    usz longest = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 32 || value > 126) return INVALID_RESULT;
        usz slot = (usz)(value - 32);
        long previous = last_seen[slot];
        if (previous >= 0 && (usz)previous >= window_start) window_start = (usz)previous + 1;
        last_seen[slot] = (long)index;
        usz current = index - window_start + 1;
        if (current > longest) longest = current;
    }
    return (long)longest;
}
