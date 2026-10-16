// Ruby Project Euler 10's strict cumulative-prime prefix.
fn isPrimeValue(number: i64) bool {
    if (number > 1 and number < 4) return true;
    if (number < 2 or @mod(number, 2) == 0 or @mod(number, 3) == 0) return false;
    var divisor: i64 = 5;
    while (divisor * divisor <= number) : (divisor += 6) {
        if (@mod(number, divisor) == 0 or @mod(number, divisor + 2) == 0) return false;
    }
    return true;
}

export fn problem10_ruby_prefix(max_total: i64) i64 {
    if (max_total < 0 or max_total > 2_000_000) return -1;
    var sum: i64 = 1;
    var value: i64 = 1;
    var number: i64 = 2;
    while (number < max_total and value < max_total) : (number += 1) {
        if (isPrimeValue(number)) {
            value += number;
            if (value < max_total) sum = value;
        }
    }
    return sum;
}
