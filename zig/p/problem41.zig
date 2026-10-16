const MAX_DIGITS: i64 = 9;

fn is_prime(number: i64) bool {
    if (number < 2) return false;
    if (number < 4) return true;
    if (@mod(number, 2) == 0 or @mod(number, 3) == 0) return false;
    var divisor: i64 = 5;
    while (divisor <= @divTrunc(number, divisor)) : (divisor += 6) {
        if (@mod(number, divisor) == 0 or @mod(number, divisor + 2) == 0) return false;
    }
    return true;
}

fn search(digits: i64, depth: i64, used: u16, value: i64) i64 {
    if (depth == digits) return if (is_prime(value)) value else 0;
    var best: i64 = 0;
    var digit: i64 = 1;
    while (digit <= digits) : (digit += 1) {
        const bit: u16 = @as(u16, 1) << @intCast(digit);
        if ((used & bit) != 0) continue;
        const candidate = search(digits, depth + 1, used | bit, value * 10 + digit);
        if (candidate > best) best = candidate;
    }
    return best;
}

export fn problem41(digits: i64) i64 {
    if (digits < 1 or digits > MAX_DIGITS) return -1;
    return search(digits, 0, 0, 0);
}
