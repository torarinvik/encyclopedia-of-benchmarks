module palindrome_number;

// Reverse half the digits to avoid overflow.
fn long palindrome_number(long value) @export("palindrome_number") {
    if (value < 0 || value > 2147483647) return -1;
    if (value != 0 && value % 10 == 0) return 0;
    long remaining = value;
    long reversed_half = 0;
    while (remaining > reversed_half) {
        reversed_half = reversed_half * 10 + remaining % 10;
        remaining /= 10;
    }
    return (remaining == reversed_half || remaining == reversed_half / 10) ? 1 : 0;
}
