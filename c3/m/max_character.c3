module max_character;

fn long max_character(long* values, usz length) @export("max_character") {
    if (length == 0 || length > 256 || values == null) return -1;
    long[26] counts;
    for (usz i = 0; i < 26; i++) counts[i] = 0;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 97 || values[i] > 122) return -1;
        counts[(usz)(values[i] - 97)] += 1;
    }
    long best = 0, code = -1;
    bool tied = false;
    for (usz i = 0; i < 26; i++) {
        if (counts[i] > best) { best = counts[i]; code = 97 + (long)i; tied = false; }
        else if (counts[i] == best && best != 0) tied = true;
    }
    return tied ? -1 : code;
}
