module check_palindrome2;

const usz MAX_LENGTH = 1024;

fn long lower_ascii(long value) {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

fn long check_palindrome2(long* values, usz length, char* output, usz output_capacity)
    @export("check_palindrome2")
{
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 32 || values[i] > 126) return -1;
    }
    usz start = 0;
    usz end = length;
    while (start < end && values[start] == 32) start++;
    while (end > start && values[end - 1] == 32) end--;
    usz normalized_length = end - start;
    if (normalized_length == 0 || (normalized_length == 1 && values[start] == '0')) return -1;

    bool palindrome = true;
    for (usz left = 0; left < normalized_length / 2; left++) {
        usz right = normalized_length - left - 1;
        if (lower_ascii(values[start + left]) != lower_ascii(values[start + right])) palindrome = false;
    }
    char* suffix = palindrome ? " - a palindrome string.\n" : " - not a palindrome string.\n";
    usz suffix_length = palindrome ? 24 : 28;
    if (output == null || output_capacity < normalized_length + suffix_length) return -2;
    for (usz i = 0; i < normalized_length; i++) output[i] = (char)lower_ascii(values[start + i]);
    for (usz i = 0; i < suffix_length; i++) output[normalized_length + i] = suffix[i];
    return (long)(normalized_length + suffix_length);
}
