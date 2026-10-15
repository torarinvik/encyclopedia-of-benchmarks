module alpha_numerical_sort;

const long INVALID_RESULT = -2;
fn bool is_digit(long value) { return value >= '0' && value <= '9'; }
fn bool valid_string(long* input, usz start, usz count) {
    for (usz i = 0; i < count; i++) {
        long value = input[start + i];
        if (!is_digit(value) && (value < 'a' || value > 'z')) return false;
        if (value == '0' && i > 0 && is_digit(input[start + i - 1])) return false;
    }
    return true;
}
fn long alpha_numerical_sort(long* input, usz length) @export("alpha_numerical_sort") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 64) return INVALID_RESULT;
    usz first_length = (usz)input[0];
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64) return INVALID_RESULT;
    usz second_length = (usz)input[1 + first_length];
    if (length != 2 + first_length + second_length) return INVALID_RESULT;
    if (!valid_string(input, 2, first_length) || !valid_string(input, 2 + first_length, second_length)) return INVALID_RESULT;
    usz i = 0;
    usz j = 0;
    while (i < first_length && j < second_length) {
        long a = input[2 + i];
        long b = input[2 + first_length + j];
        if (is_digit(a) && is_digit(b)) {
            usz end_a = i;
            usz end_b = j;
            while (end_a < first_length && is_digit(input[2 + end_a])) end_a++;
            while (end_b < second_length && is_digit(input[2 + first_length + end_b])) end_b++;
            usz digits_a = end_a - i;
            usz digits_b = end_b - j;
            if (digits_a != digits_b) return digits_a < digits_b ? -1 : 1;
            for (usz k = 0; k < digits_a; k++) {
                long ca = input[2 + i + k];
                long cb = input[2 + first_length + j + k];
                if (ca != cb) return ca < cb ? -1 : 1;
            }
            i = end_a; j = end_b;
        } else {
            if (a != b) return a < b ? -1 : 1;
            i++; j++;
        }
    }
    if (i == first_length && j == second_length) return 0;
    return i == first_length ? -1 : 1;
}
