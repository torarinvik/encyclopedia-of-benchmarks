module count_consonants;

const usz MAX_LENGTH = 4096;

fn long count_consonants(long* values, usz length) @export("count_consonants") {
    if (length == 0 || length > MAX_LENGTH || values == null) return -1;
    if (length == 1 && values[0] == 48) return -1;
    long count = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 32 || value > 126) return -1;
        if (value >= 65 && value <= 90) value += 32;
        if (value >= 97 && value <= 122 && value != 97 && value != 101 &&
            value != 105 && value != 111 && value != 117) count++;
    }
    return count;
}
