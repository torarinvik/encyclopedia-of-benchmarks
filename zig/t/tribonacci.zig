/// Portable zero-based Tribonacci recurrence for the shared i64 contract.
pub export fn tribonacci(n: i64) i64 {
    if (n < 0 or n > 73) return -1;
    if (n == 0) return 0;
    if (n <= 2) return 1;
    var previous_three: i64 = 0;
    var previous_two: i64 = 1;
    var previous_one: i64 = 1;
    var index: i64 = 3;
    while (index <= n) : (index += 1) {
        const next = previous_three + previous_two + previous_one;
        previous_three = previous_two;
        previous_two = previous_one;
        previous_one = next;
    }
    return previous_one;
}
