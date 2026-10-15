/// Check nondecreasing letter gaps after ASCII normalization and filtering.
const MAX_LENGTH: usize = 4096;

export fn check_exceeding(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -2;
    for (0..length) |index| {
        const value = values[index];
        if (value < 32 or value > 126) return -2;
    }

    var previous_letter: i64 = -1;
    var previous_gap: i64 = -1;
    for (0..length) |index| {
        var letter = values[index];
        if (letter >= 97 and letter <= 122) letter -= 32;
        if (letter < 65 or letter > 90) continue;
        if (previous_letter >= 0 and letter != previous_letter) {
            const gap = if (letter > previous_letter) letter - previous_letter else previous_letter - letter;
            if (previous_gap >= 0 and gap < previous_gap) return 0;
            previous_gap = gap;
        }
        previous_letter = letter;
    }
    return 1;
}
