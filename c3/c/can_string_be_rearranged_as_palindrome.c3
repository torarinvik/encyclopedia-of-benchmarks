module can_string_be_rearranged_as_palindrome;

// Can lowercase ASCII letters be rearranged into a palindrome?
fn long can_string_be_rearranged_as_palindrome(long* text, usz length) @export("can_string_be_rearranged_as_palindrome")
{
    if (length == 0 || length > 4096) return -1;
    usz[26] counts = {0};
    usz odd_count = 0;
    for (usz index = 0; index < length; index++) {
        long value = text[index];
        if (value < 97 || value > 122) return -1;
        usz letter = (usz)(value - 97);
        if (counts[letter] % 2 == 0) odd_count++;
        else odd_count--;
        counts[letter]++;
    }
    return odd_count <= 1 ? 1 : 0;
}
