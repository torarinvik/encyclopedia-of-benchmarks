const MAX_INPUT: i64 = 1_000_000_000;

export fn reverse_number(number: i64) i64 {
    if (number < 0 or number > MAX_INPUT) return -1;
    var current = number;
    var reversed: i64 = 0;
    while (current > 0) {
        reversed = reversed * 10 + @rem(current, 10);
        current = @divTrunc(current, 10);
    }
    return reversed;
}
