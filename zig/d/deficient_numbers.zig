/// Proper-divisor pair scan from the pinned Python source.
export fn deficient_numbers(number: i64) i64 {
    if (number <= 0) return 0;
    if (number > 100_000_000) return -1;
    if (number == 1) return 1;

    var total: i64 = 1;
    var divisor: i64 = 2;
    while (divisor <= number / divisor) : (divisor += 1) {
        if (number % divisor == 0) {
            const other = number / divisor;
            total += divisor;
            if (other != divisor) total += other;
        }
    }
    return if (total < number) 1 else 0;
}
