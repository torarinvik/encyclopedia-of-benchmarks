module valid_palindrome;

// ASCII alphanumeric palindrome check, ignoring case and punctuation.
fn bool is_ascii_alphanumeric(long value) {
    return (value >= 48 && value <= 57) || (value >= 65 && value <= 90) ||
           (value >= 97 && value <= 122);
}

fn long ascii_lower(long value) {
    return value >= 65 && value <= 90 ? value + 32 : value;
}

fn long valid_palindrome(long* text, usz length) @export("valid_palindrome") {
    if (length > 4096) return -1;
    for (usz index = 0; index < length; index++) {
        if (text[index] < 0 || text[index] > 127) return -1;
    }
    usz left = 0;
    usz right = length;
    while (left < right) {
        while (left < right && !is_ascii_alphanumeric(text[left])) left++;
        while (left < right && !is_ascii_alphanumeric(text[right - 1])) right--;
        if (left < right && ascii_lower(text[left]) != ascii_lower(text[right - 1])) return 0;
        if (left < right) { left++; right--; }
    }
    return 1;
}
