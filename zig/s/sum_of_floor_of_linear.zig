const MAX_PARAMETER: i64 = 1_000_000_000;

fn floorSum(n_input: i64, m_input: i64, a_input: i64, b_input: i64) i64 {
    var n = n_input;
    var m = m_input;
    var a = a_input;
    var b = b_input;
    var answer: i64 = 0;
    while (true) {
        if (a >= m) {
            const quotient = @divTrunc(a, m);
            var left = n;
            var right = n - 1;
            if (@mod(left, 2) == 0) left = @divTrunc(left, 2) else right = @divTrunc(right, 2);
            answer += left * right * quotient;
            a = @mod(a, m);
        }
        if (b >= m) {
            answer += n * @divTrunc(b, m);
            b = @mod(b, m);
        }
        const numerator = a * n + b;
        const height = @divTrunc(numerator, m);
        if (height == 0) return answer;
        b = @mod(numerator, m);
        n = height;
        const previous_m = m;
        m = a;
        a = previous_m;
    }
}

export fn sum_of_floor_of_linear(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 4) return -1;
    const values = input.?[0..4];
    const n = values[0];
    const m = values[1];
    const a = values[2];
    const b = values[3];
    if (n < 1 or n > MAX_PARAMETER or m < 1 or m > MAX_PARAMETER) return -1;
    if (a < 0 or a >= m or b < 0 or b >= m) return -1;
    return floorSum(n, m, a, b);
}
