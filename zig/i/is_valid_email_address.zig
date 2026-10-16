fn asciiLetter(value: i64) bool {
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
}
fn asciiDigit(value: i64) bool { return value >= 48 and value <= 57; }
fn localSpecial(value: i64) bool {
    return value == 33 or value == 35 or value == 36 or value == 37 or value == 38 or value == 39 or
        value == 40 or value == 41 or value == 42 or value == 43 or value == 45 or value == 46 or
        value == 47 or value == 61 or value == 63 or value == 94 or value == 95 or value == 96 or
        value == 123 or value == 124 or value == 125 or value == 126;
}
fn localAllowed(value: i64) bool { return asciiLetter(value) or asciiDigit(value) or localSpecial(value); }
fn domainAllowed(value: i64) bool { return asciiLetter(value) or asciiDigit(value) or value == 46 or value == 45; }

export fn is_valid_email_address(values: [*c]const i64, length: usize) i64 {
    if (length > 320) return 0;
    if (values == null and length > 0) return -1;
    for (0..length) |index| if (values[index] < 0 or values[index] > 0x10ffff) return -1;
    var at = length;
    for (0..length) |index| {
        if (values[index] == 64) {
            if (at != length) return 0;
            at = index;
        }
    }
    if (at == length) return 0;
    const domainStart = at + 1;
    if (at > 64 or length - domainStart > 255) return 0;
    for (0..at) |index| {
        const value = values[index];
        if (!localAllowed(value)) return 0;
        if (value == 46 and (index == 0 or index + 1 == at or values[index - 1] == 46)) return 0;
    }
    var index = domainStart;
    while (index < length) : (index += 1) {
        const value = values[index];
        if (!domainAllowed(value)) return 0;
        if (value == 45 and index == domainStart) return 0;
        if (value == 46 and (index == domainStart or index + 1 == length or values[index - 1] == 46)) return 0;
    }
    return 1;
}
