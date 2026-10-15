/// Multiplicative persistence for nonnegative Java int inputs.
export fn number_persistence(input_value: i64) i64 {
    if (input_value < 0 or input_value > 2_147_483_647) return -1;
    var input = input_value;
    var steps: i64 = 0;
    while (input >= 10) {
        var product: i64 = 1;
        var remaining = input;
        while (remaining > 0) {
            product *= @mod(remaining, 10);
            remaining = @divTrunc(remaining, 10);
        }
        input = product;
        steps += 1;
    }
    return steps;
}
