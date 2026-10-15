/// Compute the source's repeated-digit-sum result from n and k.
fn digitSum(number: i64) i64 {
    var remaining = number;
    var sum: i64 = 0;
    while (remaining != 0) {
        sum += @rem(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return sum;
}

export fn recursive_digit_sum(number: i64, repetitions: i64) i64 {
    if (number < 0 or repetitions < 0 or repetitions > 1_000_000) return -1;
    var total = digitSum(number) * repetitions;
    while (total >= 10) total = digitSum(total);
    return total;
}
