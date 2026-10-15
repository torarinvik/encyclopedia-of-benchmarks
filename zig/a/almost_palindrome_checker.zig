const MAX_LENGTH: usize = 100_000;

fn isPalindromeRange(text: [*]const i64, left_start: usize, right_start: usize) bool {
    var left = left_start;
    var right = right_start;
    while (left < right) {
        if (text[left] != text[right - 1]) return false;
        left += 1;
        right -= 1;
    }
    return true;
}

export fn almost_palindrome_checker(text: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (text[index] < 97 or text[index] > 122) return -1;
    }
    var left: usize = 0;
    var right: usize = length;
    while (left < right) {
        if (text[left] != text[right - 1])
            return if (isPalindromeRange(text, left + 1, right) or
                isPalindromeRange(text, left, right - 1)) 1 else 0;
        left += 1;
        right -= 1;
    }
    return 1;
}
