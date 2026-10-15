module percentage_of_letters;

fn long percentage_of_letters(long* values, usz length) @export("percentage_of_letters") {
    if (length < 2 || length > 4097 || values == null) return -1;
    long target = values[0];
    if (target >= 65 && target <= 90) target += 32;
    if (target < 97 || target > 122) return -1;
    usz text_length = length - 1;
    usz matches = 0;
    for (usz index = 0; index < text_length; index++) {
        long value = values[index + 1];
        if (value < 0 || value > 127) return -1;
        if (value >= 65 && value <= 90) value += 32;
        if (value == target) matches++;
    }
    return (long)((100 * matches) / text_length);
}
