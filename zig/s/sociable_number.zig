/// Exact-cycle sociable-number check adapted from the pinned Java source.
fn sum_proper_divisors(number: u64) u64 {
    if (number <= 1) return 0;
    var total: u64 = 1;
    var divisor: u64 = 2;
    while (divisor <= number / divisor) : (divisor += 1) {
        if (number % divisor == 0) {
            const other = number / divisor;
            total += divisor;
            if (other != divisor) total += other;
        }
    }
    return total;
}

export fn sociable_number(number: u64, cycle_length: u64) i64 {
    if (number == 0 or number > 100_000 or cycle_length < 2 or cycle_length > 3) return -1;
    var current = number;
    var step: u64 = 0;
    while (step < cycle_length) : (step += 1) {
        current = sum_proper_divisors(current);
        if (current == number) return if (step == cycle_length - 1) 1 else 0;
    }
    return 0;
}
