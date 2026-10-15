module check_kebab_case;

const usz MAX_LENGTH = 4096;

fn bool is_ascii_word(long value) {
    return (value >= 97 && value <= 122) || (value >= 65 && value <= 90) ||
           (value >= 48 && value <= 57);
}

fn long check_kebab_case(long* values, usz length) @export("check_kebab_case") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -2;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 32 || values[i] > 126) return -2;
    }
    for (usz i = 0; i < length; i++) {
        if (values[i] == 95) return 0;
    }
    if (length < 3) return 0;
    for (usz i = 1; i + 1 < length; i++) {
        if (values[i] == 45 && is_ascii_word(values[i - 1]) && is_ascii_word(values[i + 1])) return 1;
    }
    return 0;
}
