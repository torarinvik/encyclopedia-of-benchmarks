fn isAsciiAlphanumeric(value: i64) bool {
    return (value >= 48 and value <= 57) or (value >= 65 and value <= 90) or
        (value >= 97 and value <= 122);
}

fn asciiLower(value: i64) i64 {
    return if (value >= 65 and value <= 90) value + 32 else value;
}

/// ASCII alphanumeric palindrome check, ignoring case and punctuation.
export fn valid_palindrome(text: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    if (length == 0) return 1;
    for (0..length) |index| {
        if (text[index] < 0 or text[index] > 127) return -1;
    }
    var left: usize = 0;
    var right: usize = length;
    while (left < right) {
        while (left < right and !isAsciiAlphanumeric(text[left])) left += 1;
        while (left < right and !isAsciiAlphanumeric(text[right - 1])) right -= 1;
        if (left < right and asciiLower(text[left]) != asciiLower(text[right - 1])) return 0;
        if (left < right) { left += 1; right -= 1; }
    }
    return 1;
}
