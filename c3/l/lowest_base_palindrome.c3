module lowest_base_palindrome;

fn bool is_palindromic_in_base(long number, long base) {
    if (number <= 1) return true;
    if (number % base == 0) return false;
    long remaining = number;
    long reversed = 0;
    while (remaining > 0) {
        reversed = reversed * base + remaining % base;
        remaining /= base;
    }
    return reversed == number;
}

fn long lowest_base_palindrome(long number) @export("lowest_base_palindrome") {
    if (number < 0 || number > 64) return -1;
    long base = 2;
    while (!is_palindromic_in_base(number, base)) base++;
    return base;
}
