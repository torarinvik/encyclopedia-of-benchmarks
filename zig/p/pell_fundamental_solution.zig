fn fundamentalSolution(discriminant: i64) struct { x: i64, y: i64 } {
    var root: i64 = 0;
    while ((root + 1) * (root + 1) <= discriminant) : (root += 1) {}

    var previous_numerator: i64 = 0;
    var numerator: i64 = 1;
    var previous_denominator: i64 = 1;
    var denominator: i64 = 0;
    var m: i64 = 0;
    var d: i64 = 1;
    var a = root;
    while (true) {
        const next_numerator = a * numerator + previous_numerator;
        const next_denominator = a * denominator + previous_denominator;
        if (next_numerator * next_numerator - discriminant * next_denominator * next_denominator == 1) {
            return .{ .x = next_numerator, .y = next_denominator };
        }

        previous_numerator = numerator;
        numerator = next_numerator;
        previous_denominator = denominator;
        denominator = next_denominator;

        m = d * a - m;
        d = @divTrunc(discriminant - m * m, d);
        a = @divTrunc(root + m, d);
    }
}

export fn pell_fundamental_solution(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const discriminant = input_opt.?[0];
    if (discriminant < 2 or discriminant > 31) return -1;

    var root: i64 = 0;
    while ((root + 1) * (root + 1) <= discriminant) : (root += 1) {}
    if (root * root == discriminant) return -1;

    const solution = fundamentalSolution(discriminant);
    return (solution.x << 32) | solution.y;
}
