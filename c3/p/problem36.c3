module problem36;

const long MAX_LIMIT = 1000000;

fn bool is_decimal_palindrome(long value) {
    long remaining = value;
    long reversed = 0;
    while (remaining > 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    return reversed == value;
}

fn bool is_binary_palindrome(long value) {
    long remaining = value;
    long reversed = 0;
    while (remaining > 0) {
        reversed = reversed * 2 + remaining % 2;
        remaining /= 2;
    }
    return reversed == value;
}

fn long problem36(long limit) @export("problem36") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    long total = 0;
    for (long value = 1; value < limit; value++) {
        if (is_decimal_palindrome(value) && is_binary_palindrome(value)) total += value;
    }
    return total;
}
