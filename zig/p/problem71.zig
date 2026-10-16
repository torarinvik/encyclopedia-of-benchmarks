/// Find the numerator of the closest bounded fraction below a reduced target.
const MAX_DENOMINATOR: i64 = 1_000_000;

fn gcdPositive(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

export fn problem71(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const target_numerator = input[0];
    const target_denominator = input[1];
    const limit = input[2];
    if (target_numerator < 1 or target_denominator <= target_numerator or
        target_denominator > MAX_DENOMINATOR or limit < 1 or limit > MAX_DENOMINATOR or
        gcdPositive(target_numerator, target_denominator) != 1) return -1;

    var best_numerator: i64 = 0;
    var best_denominator: i64 = 1;
    var current_denominator: i64 = 1;
    while (current_denominator <= limit) : (current_denominator += 1) {
        var current_numerator = @divTrunc(current_denominator * target_numerator, target_denominator);
        if (@rem(current_denominator, target_denominator) == 0) current_numerator -= 1;
        if (current_numerator * best_denominator > current_denominator * best_numerator) {
            best_numerator = current_numerator;
            best_denominator = current_denominator;
        }
    }
    return best_numerator;
}
