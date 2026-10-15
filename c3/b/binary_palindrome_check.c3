module binary_palindrome_check;

fn long binary_palindrome_check(long number) @export("binary_palindrome_check") {
    if (number < -2147483648 || number > 2147483647) return -1;
    if (number < 0) return 0;
    long remaining = number;
    long reversed = 0;
    while (remaining > 0) {
        reversed = (reversed << 1) | (remaining & 1);
        remaining >>= 1;
    }
    return reversed == number ? 1 : 0;
}
