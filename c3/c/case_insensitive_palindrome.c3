module case_insensitive_palindrome;

fn long ascii_lower(long value) {
    if (value >= 65 && value <= 90) return value + 32;
    return value;
}


// Check whether an ASCII string is a palindrome ignoring ASCII letter case.
fn long case_insensitive_palindrome(long* values, usz length) @export("case_insensitive_palindrome")
{
    if (length > 4096) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    for (usz left = 0; left < length / 2; left++) {
        if (ascii_lower(values[left]) != ascii_lower(values[length - 1 - left])) return 0;
    }
    return 1;
}
