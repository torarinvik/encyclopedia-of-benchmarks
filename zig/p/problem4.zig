fn isPalindrome(value: i64) bool {
    var remaining = value;
    var reversed: i64 = 0;
    while (remaining > 0) {
        reversed = reversed * 10 + @rem(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return reversed == value;
}

export fn problem4(digits: i64) i64 {
    if (digits < 1 or digits > 3) return -1;
    const minimum: i64 = if (digits == 1) 1 else if (digits == 2) 10 else 100;
    const maximum: i64 = if (digits == 1) 9 else if (digits == 2) 99 else 999;
    var largest: i64 = 0;
    var first = maximum;
    while (first >= minimum and first * maximum > largest) : (first -= 1) {
        var second = maximum;
        while (second >= first and first * second > largest) : (second -= 1) {
            const product = first * second;
            if (isPalindrome(product)) largest = product;
        }
    }
    return largest;
}
