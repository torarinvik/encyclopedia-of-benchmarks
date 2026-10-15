module title_case_conversion;

fn long title_case_conversion(long* input, usz length, char* output, usz output_capacity) @export("title_case_conversion") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > 256) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if ((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) continue;
        if (value == ' ' && i > 0 && i + 1 < n && input[i] != ' ') continue;
        return -1;
    }
    if (output == null || output_capacity < n + 1) return -2;
    bool at_word_start = true;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value == ' ') {
            output[i] = (char)value;
            at_word_start = true;
        } else if (at_word_start) {
            if (value >= 'a' && value <= 'z') value -= 'a' - 'A';
            output[i] = (char)value;
            at_word_start = false;
        } else {
            if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
            output[i] = (char)value;
        }
    }
    output[n] = 0;
    return (long)n;
}
