/// Exact perfect-square check using integer binary search and division.
export fn perfect_square(input: i64) i64 {
    if (input < 0) return 0;
    if (input < 2) return 1;
    const number: u64 = @intCast(input);
    var low: u64 = 1;
    var high: u64 = number / 2;
    while (low <= high) {
        const middle = low + (high - low) / 2;
        const quotient = number / middle;
        if (quotient == middle) {
            if (number % middle == 0) return 1;
            low = middle + 1;
        } else if (quotient < middle) {
            high = middle - 1;
        } else {
            low = middle + 1;
        }
    }
    return 0;
}
