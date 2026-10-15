module isogram;

// Check whether ASCII letters form an isogram, ignoring case and spaces.
fn long isogram(long* values, usz length) @export("isogram") {
    if (length > 4096 || (length != 0 && values == null)) return -1;
    bool[26] seen;
    for (usz letter = 0; letter < 26; letter++) seen[letter] = false;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value == 32) continue;
        if (value >= 65 && value <= 90) value += 32;
        if (value < 97 || value > 122) return -1;
        usz letter = (usz)(value - 97);
        if (seen[letter]) return 0;
        seen[letter] = true;
    }
    return 1;
}
