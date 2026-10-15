module almost_palindrome_checker;

const long MAX_LENGTH = 100000;

fn bool is_palindrome_range(long* text, usz left, usz right) {
    while (left < right) {
        if (text[left] != text[right - 1]) return false;
        left++;
        right--;
    }
    return true;
}

fn long almost_palindrome_checker(long* text, usz length) @export("almost_palindrome_checker") {
    if (length > MAX_LENGTH) return -1;
    for (usz index = 0; index < length; index++)
        if (text[index] < 97 || text[index] > 122) return -1;
    usz left = 0;
    usz right = length;
    while (left < right) {
        if (text[left] != text[right - 1]) {
            if (is_palindrome_range(text, left + 1, right) ||
                is_palindrome_range(text, left, right - 1)) return 1;
            return 0;
        }
        left++;
        right--;
    }
    return 1;
}
