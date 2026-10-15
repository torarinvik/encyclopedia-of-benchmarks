module knuth_morris_pratt;

// Return the first byte match index, or -1 when there is no match.
fn long knuth_morris_pratt(long* packed, usz length) @export("knuth_morris_pratt") {
    if (packed == null || length < 2 || length > 8194) return -1;
    if (packed[0] < 0 || packed[0] > 4096 || packed[1] < 0 || packed[1] > 4096) return -1;
    usz text_length = (usz)packed[0];
    usz pattern_length = (usz)packed[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz index = 0; index < text_length + pattern_length; index++) {
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    }
    if (pattern_length == 0) return 0;

    usz pattern_start = 2 + text_length;
    usz[4096] prefix;
    prefix[0] = 0;
    usz index = 1;
    usz matched = 0;
    while (index < pattern_length) {
        while (matched > 0 && packed[pattern_start + index] != packed[pattern_start + matched]) {
            matched = prefix[matched - 1];
        }
        if (packed[pattern_start + index] == packed[pattern_start + matched]) matched++;
        prefix[index] = matched;
        index++;
    }

    index = 0;
    matched = 0;
    while (index < text_length) {
        while (matched > 0 && packed[2 + index] != packed[pattern_start + matched]) {
            matched = prefix[matched - 1];
        }
        if (packed[2 + index] == packed[pattern_start + matched]) matched++;
        if (matched == pattern_length) return (long)(index + 1 - pattern_length);
        index++;
    }
    return -1;
}
