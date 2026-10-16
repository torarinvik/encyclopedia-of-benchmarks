/// Count non-bouncy positive integers with at most the requested digits.
const MAX_DIGITS: i64 = 100;

fn chooseInteger(n: i64, r: i64) i64 {
    var result: i64 = 1;
    var i: i64 = 1;
    while (i <= r) : (i += 1) result = @divTrunc(result * (n + 1 - i), i);
    return result;
}

fn nonBouncyExact(digits: i64) i64 {
    return chooseInteger(8 + digits, digits) + chooseInteger(9 + digits, digits) - 10;
}

export fn problem113(num_digits: i64) i64 {
    if (num_digits > MAX_DIGITS) return -1;
    var total: i64 = 0;
    var digits: i64 = 1;
    while (digits <= num_digits) : (digits += 1) total += nonBouncyExact(digits);
    return total;
}
