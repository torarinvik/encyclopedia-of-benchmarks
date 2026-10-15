module detect_capital_usage;

const MAX_LENGTH = 1024;

fn bool is_upper(long value) { return value >= 65 && value <= 90; }
fn bool is_lower(long value) { return value >= 97 && value <= 122; }
fn bool valid_input(long* input, usz length) {
    if (length > MAX_LENGTH || (length != 0 && input == null)) { return false; }
    for (usz index = 0; index < length; index++) {
        if (!is_upper(input[index]) && !is_lower(input[index])) { return false; }
    }
    return true;
}

// Classify by counting uppercase letters.
fn long detect_capital_usage(long* input, usz length) @export("detect_capital_usage") {
    if (!valid_input(input, length)) { return -1; }
    usz uppercase_count = 0;
    for (usz index = 0; index < length; index++) {
        if (is_upper(input[index])) { uppercase_count++; }
    }
    if (uppercase_count == 0 || uppercase_count == length ||
        (uppercase_count == 1 && length != 0 && is_upper(input[0]))) { return 1; }
    return 0;
}
