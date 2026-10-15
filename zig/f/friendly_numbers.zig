/// Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior.
fn abundancyIndex(number: u64) f64 {
    var sum = number;
    var divisor: u64 = 1;
    while (divisor * 2 < number) : (divisor += 1) {
        if (number % divisor == 0) sum += divisor;
    }
    return @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(number));
}

export fn friendly_numbers(first: u64, second: u64) i64 {
    if (first == 0 or second == 0 or first == second or first > 1000 or second > 1000) return -1;
    return if (abundancyIndex(first) == abundancyIndex(second)) 1 else 0;
}
