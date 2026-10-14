module palindrome;

// Check whether an exact ASCII string is a palindrome.
fn long palindrome(long* values, usz length) @export("palindrome")
{
    if (length > 4096) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    for (usz left = 0; left < length / 2; left++) {
        if (values[left] != values[length - 1 - left]) return 0;
    }
    return 1;
}
