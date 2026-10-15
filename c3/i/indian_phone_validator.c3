module indian_phone_validator;

fn bool is_ascii_whitespace(long value) {
    return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32;
}

fn bool mobile_tail(long* phone, usz end, usz position) {
    if (position > end || end - position != 10) return false;
    if (phone[position] < '7' || phone[position] > '9') return false;
    for (usz i = 1; i < 10; i++) {
        if (phone[position + i] < '0' || phone[position + i] > '9') return false;
    }
    return true;
}

fn long indian_phone_validator(long* phone, usz length) @export("indian_phone_validator") {
    if (phone == null || length == 0 || length > 18) return -1;
    for (usz i = 0; i < length; i++) {
        if (phone[i] < 0 || phone[i] > 127) return -1;
    }

    usz end = length;
    if (phone[end - 1] == '\n') end -= 1;
    usz prefix = 0;
    if (end >= 3 && phone[0] == '+' && phone[1] == '9' && phone[2] == '1') {
        prefix = 3;
        if (prefix < end && (phone[prefix] == '-' || is_ascii_whitespace(phone[prefix]))) prefix += 1;
    }

    for (int zero = 0; zero <= 1; zero++) {
        usz after_zero = prefix;
        if (zero == 1) {
            if (after_zero >= end || phone[after_zero] != '0') continue;
            after_zero += 1;
        }
        for (int country = 0; country <= 1; country++) {
            usz position = after_zero;
            if (country == 1) {
                if (position + 2 > end || phone[position] != '9' || phone[position + 1] != '1') continue;
                position += 2;
            }
            if (mobile_tail(phone, end, position)) return 1;
        }
    }
    return 0;
}
