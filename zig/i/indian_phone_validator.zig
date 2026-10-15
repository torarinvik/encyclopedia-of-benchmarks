fn is_ascii_whitespace(value: i64) bool {
    return value == 9 or value == 10 or value == 11 or value == 12 or value == 13 or value == 32;
}

fn mobile_tail(phone: []const i64, ending: usize, position: usize) bool {
    if (position > ending or ending - position != 10) return false;
    if (phone[position] < 55 or phone[position] > 57) return false;
    for (phone[position + 1 .. ending]) |digit| {
        if (digit < 48 or digit > 57) return false;
    }
    return true;
}

export fn indian_phone_validator(phone: ?[*]const i64, length: usize) i64 {
    if (phone == null or length == 0 or length > 18) return -1;
    const values = phone.?[0..length];
    for (values) |value| {
        if (value < 0 or value > 127) return -1;
    }

    var ending = length;
    if (values[ending - 1] == 10) ending -= 1;
    var prefix: usize = 0;
    if (ending >= 3 and values[0] == 43 and values[1] == 57 and values[2] == 49) {
        prefix = 3;
        if (prefix < ending and (values[prefix] == 45 or is_ascii_whitespace(values[prefix]))) prefix += 1;
    }

    for (0..2) |zero| {
        var after_zero = prefix;
        if (zero == 1) {
            if (after_zero >= ending or values[after_zero] != 48) continue;
            after_zero += 1;
        }
        for (0..2) |country| {
            var position = after_zero;
            if (country == 1) {
                if (position + 2 > ending or values[position] != 57 or values[position + 1] != 49) continue;
                position += 2;
            }
            if (mobile_tail(values, ending, position)) return 1;
        }
    }
    return 0;
}
