/// Count repeated decimal digit-sum steps until one digit remains.
export fn additive_persistence(input_value: i64) i64 {
    if (input_value < 0) return -1;
    var input = input_value;
    var steps: i64 = 0;
    while (input >= 10) {
        var total: i64 = 0;
        var remaining = input;
        while (remaining > 0) {
            total += @mod(remaining, 10);
            remaining = @divTrunc(remaining, 10);
        }
        input = total;
        steps += 1;
    }
    return steps;
}
