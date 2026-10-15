fn proper_divisor_sum(number: u64) u64 {
    if (number <= 1) return 0;
    var sum: u64 = 1;
    var divisor: u64 = 2;
    while (divisor <= number / divisor) : (divisor += 1) {
        if (number % divisor == 0) {
            sum += divisor;
            const partner = number / divisor;
            if (partner != divisor) sum += partner;
        }
    }
    return sum;
}

export fn amicable_number(left: u64, right: u64) i64 {
    if (left < 1 or left > 1_000_000_000 or right < 1 or right > 1_000_000_000) return -1;
    if (left == right) return 0;
    return @intFromBool(proper_divisor_sum(left) == right and proper_divisor_sum(right) == left);
}
