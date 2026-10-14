module regex_match;

// Direct recursive full-string matching for the . and * regular-expression subset.
fn bool regex_match_recursive(long* values, usz text_length, usz pattern_start,
                              usz pattern_length, usz text_index, usz pattern_index)
{
    if (pattern_index == pattern_length) return text_index == text_length;
    long atom = values[pattern_start + pattern_index];
    if (pattern_index + 1 < pattern_length && values[pattern_start + pattern_index + 1] == '*') {
        if (regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                  text_index, pattern_index + 2)) return true;
        return text_index < text_length && (atom == '.' || atom == values[2 + text_index])
            && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                     text_index + 1, pattern_index);
    }
    return text_index < text_length && (atom == '.' || atom == values[2 + text_index])
        && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                 text_index + 1, pattern_index + 1);
}

fn long regex_match(long* values, usz length) @export("regex_match")
{
    if (length < 2) return -1;
    if (values[0] < 0 || values[0] > 12 || values[1] < 0 || values[1] > 20) return -1;
    usz text_length = (usz)values[0];
    usz pattern_length = (usz)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    usz pattern_start = 2 + text_length;
    for (usz index = 0; index < text_length; index++) {
        if (values[2 + index] < 'a' || values[2 + index] > 'z') return -1;
    }
    for (usz index = 0; index < pattern_length; index++) {
        long symbol = values[pattern_start + index];
        if (!((symbol >= 'a' && symbol <= 'z') || symbol == '.' || symbol == '*')) return -1;
        if (symbol == '*' && (index == 0 || values[pattern_start + index - 1] == '*')) return -1;
    }
    return regex_match_recursive(values, text_length, pattern_start, pattern_length, 0, 0) ? 1 : 0;
}
