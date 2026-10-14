/// Fibonacci search in an ascending sequence for the shared benchmark contract.
export fn fibonacci_search(values: [*]const i64, length: usize, target: i64) i64 {
    if (length == 0) return -1;
    const slice = values[0..length];
    var fib_minus_two: usize = 0;
    var fib_minus_one: usize = 1;
    var fib: usize = 1;
    while (fib < length) {
        fib_minus_two = fib_minus_one;
        fib_minus_one = fib;
        fib = fib_minus_two + fib_minus_one;
    }

    var offset_plus_one: usize = 0;
    while (fib > 1) {
        var index = offset_plus_one + fib_minus_two - 1;
        if (index >= length) index = length - 1;
        const value = slice[index];
        if (value == target) return @intCast(index);
        if (value < target) {
            fib = fib_minus_one;
            fib_minus_one = fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
            offset_plus_one = index + 1;
        } else {
            fib = fib_minus_two;
            fib_minus_one -= fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
        }
    }
    if (fib_minus_one != 0 and offset_plus_one < length and slice[offset_plus_one] == target) {
        return @intCast(offset_plus_one);
    }
    return -1;
}
