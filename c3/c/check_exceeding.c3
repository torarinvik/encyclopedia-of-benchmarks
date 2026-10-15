module check_exceeding;

const usz MAX_LENGTH = 4096;

// Check nondecreasing letter gaps after ASCII normalization and filtering.
fn long check_exceeding(long* values, usz length) @export("check_exceeding") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -2;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 32 || values[i] > 126) return -2;
    }

    int previous_letter = -1;
    int previous_gap = -1;
    for (usz i = 0; i < length; i++) {
        int letter = (int)values[i];
        if (letter >= 97 && letter <= 122) letter -= 32;
        if (letter < 65 || letter > 90) continue;
        if (previous_letter >= 0 && letter != previous_letter) {
            int gap = letter > previous_letter ? letter - previous_letter : previous_letter - letter;
            if (previous_gap >= 0 && gap < previous_gap) return 0;
            previous_gap = gap;
        }
        previous_letter = letter;
    }
    return 1;
}
