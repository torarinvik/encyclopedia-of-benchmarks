const MAX_INPUT_LENGTH: usize = 2;

export fn euler_problem_6(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 100 or length != 1) return -1;
    const n: i64 = input[0];

    var sum: i64 = 0;
    var sum_of_squares: i64 = 0;
    var value: i64 = 1;
    while (value <= n) : (value += 1) {
        sum += value;
        sum_of_squares += value * value;
    }
    return sum * sum - sum_of_squares;
}
