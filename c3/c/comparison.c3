module comparison;

const usz MAX_STRING_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 3 + 2 * MAX_STRING_LENGTH;

fn long fold_ascii(long value, long mode) {
    if (mode == 1 && value >= 'A' && value <= 'Z') return value + ('a' - 'A');
    return value;
}

fn long comparison(long* values, usz length) @export("comparison") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return -2;
    long mode = values[0];
    long first_length_value = values[1];
    if ((mode != 0 && mode != 1) || first_length_value < 0 || first_length_value > (long)MAX_STRING_LENGTH) return -2;
    usz first_length = (usz)first_length_value;
    usz second_length_position = 2 + first_length;
    if (second_length_position >= length) return -2;
    long second_length_value = values[second_length_position];
    if (second_length_value < 0 || second_length_value > (long)MAX_STRING_LENGTH) return -2;
    usz second_length = (usz)second_length_value;
    usz second_start = second_length_position + 1;
    if (second_start + second_length != length) return -2;

    for (usz index = 0; index < first_length; index += 1) {
        long value = values[2 + index];
        if (value < 1 || value > 127) return -2;
    }
    for (usz index = 0; index < second_length; index += 1) {
        long value = values[second_start + index];
        if (value < 1 || value > 127) return -2;
    }

    usz common_length = first_length < second_length ? first_length : second_length;
    for (usz index = 0; index < common_length; index += 1) {
        long left = fold_ascii(values[2 + index], mode);
        long right = fold_ascii(values[second_start + index], mode);
        if (left < right) return -1;
        if (left > right) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}
