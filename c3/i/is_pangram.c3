module is_pangram;

// ASCII pangram predicate: ignore nonletters and ASCII letter case.
fn long is_pangram(long* values, usz length) @export("is_pangram") {
    if (length > 4096 || (length != 0 && values == null)) return -1;
    bool[26] seen;
    for (usz letter = 0; letter < 26; letter++) seen[letter] = false;
    usz found = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 0 || value > 127) return -1;
        if (value >= 65 && value <= 90) value += 32;
        if (value >= 97 && value <= 122) {
            usz letter = (usz)(value - 97);
            if (!seen[letter]) {
                seen[letter] = true;
                found++;
            }
        }
    }
    return found == 26 ? 1 : 0;
}
