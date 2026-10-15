module detect_capital_usage_scan;

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

// Recheck the whole word for every uppercase byte after the first.
fn long detect_capital_usage_scan(long* input, usz length) @export("detect_capital_usage_scan") {
    if (!valid_input(input, length)) { return -1; }
    for (usz index = 1; index < length; index++) {
        if (is_upper(input[index])) {
            bool all_upper = true;
            for (usz check = 0; check < length; check++) {
                if (is_lower(input[check])) { all_upper = false; break; }
            }
            if (!all_upper) { return 0; }
        }
    }
    return 1;
}
