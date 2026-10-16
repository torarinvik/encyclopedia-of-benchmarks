module word_pattern_matcher;

fn bool match_at(long* pattern, long* text, usz plen, usz tlen, usz pi, usz ti,
                 int* starts, int* lengths) {
    if (pi == plen) return ti == tlen;
    int symbol = (int)(pattern[pi] - 32);
    if (lengths[symbol] >= 0) {
        usz size = (usz)lengths[symbol];
        if (ti + size > tlen) return false;
        for (usz j = 0; j < size; j++) if (text[ti + j] != text[starts[symbol] + (int)j]) return false;
        return match_at(pattern, text, plen, tlen, pi + 1, ti + size, starts, lengths);
    }
    for (usz size = 1; ti + size <= tlen; size++) {
        bool used = false;
        for (int other = 0; other < 95; other++) if (lengths[other] == (int)size) {
            bool same = true;
            for (usz j = 0; j < size; j++) if (text[ti + j] != text[starts[other] + (int)j]) { same = false; break; }
            if (same) { used = true; break; }
        }
        if (used) continue;
        starts[symbol] = (int)ti; lengths[symbol] = (int)size;
        if (match_at(pattern, text, plen, tlen, pi + 1, ti + size, starts, lengths)) return true;
        lengths[symbol] = -1;
    }
    return false;
}

fn long word_pattern_matcher(long* input, usz length, char* output, usz capacity) @export("word_pattern_matcher") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 8) return -1;
    usz plen = (usz)input[0];
    if (length < plen + 2) return -1;
    usz text_index = plen + 1;
    long tlen_raw = input[text_index];
    if (tlen_raw < 0 || tlen_raw > 32 || length != text_index + 1 + (usz)tlen_raw) return -1;
    usz tlen = (usz)tlen_raw;
    for (usz i = 0; i < plen; i++) if (input[i + 1] < 32 || input[i + 1] > 126) return -1;
    for (usz i = 0; i < tlen; i++) if (input[text_index + 1 + i] < 32 || input[text_index + 1 + i] > 126) return -1;
    int[95] starts; int[95] lengths;
    for (int i = 0; i < 95; i++) { starts[i] = -1; lengths[i] = -1; }
    return match_at(input + 1, input + text_index + 1, plen, tlen, 0, 0, &starts[0], &lengths[0]) ? 1 : 0;
}
