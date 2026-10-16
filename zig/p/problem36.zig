const MAX_LIMIT: i64 = 1_000_000;

fn is_decimal_palindrome(value: i64) bool {
    var remaining = value;
    var reversed: i64 = 0;
    while (remaining > 0) {
        reversed = reversed * 10 + @mod(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return reversed == value;
}

fn is_binary_palindrome(value: i64) bool {
    var remaining = value;
    var reversed: i64 = 0;
    while (remaining > 0) {
        reversed = reversed * 2 + @mod(remaining, 2);
        remaining = @divTrunc(remaining, 2);
    }
    return reversed == value;
}

export fn problem36(limit: i64) i64 {
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    var total: i64 = 0;
    var value: i64 = 1;
    while (value < limit) : (value += 1) {
        if (is_decimal_palindrome(value) and is_binary_palindrome(value)) total += value;
    }
    return total;
}
