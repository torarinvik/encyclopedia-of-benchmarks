module problem4;

fn bool is_palindrome(long value) {
    long original = value;
    long reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return reversed == original;
}

fn long problem4(long digits) @export("problem4") {
    if (digits < 1 || digits > 3) return -1;
    long minimum = digits == 1 ? 1 : (digits == 2 ? 10 : 100);
    long maximum = digits == 1 ? 9 : (digits == 2 ? 99 : 999);
    long largest = 0;
    for (long first = maximum; first >= minimum && first * maximum > largest; first--) {
        for (long second = maximum; second >= first && first * second > largest; second--) {
            long product = first * second;
            if (is_palindrome(product)) largest = product;
        }
    }
    return largest;
}
