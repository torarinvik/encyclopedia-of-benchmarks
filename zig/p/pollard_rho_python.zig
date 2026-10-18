const MIN_NUM: i64 = 2;
const MAX_NUM: i64 = 1_000_000;

fn gcdNonnegative(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn advance(value: i64, step: i64, modulus: i64) i64 {
    return @mod(value * value + step, modulus);
}

export fn pollard_rho_python(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 5) return -1;
    const values = input.?;
    const num = values[0];
    var seed = values[1];
    var step = values[2];
    const attempts = values[3];
    const step_limit = values[4];
    if (num < MIN_NUM or num > MAX_NUM or seed < 0 or seed >= num or step < 0 or step > 1000 or
        attempts < 1 or attempts > 8 or step_limit < 1 or step_limit > 64) return -1;
    if (num > 2 and @rem(num, 2) == 0) return 2;

    var attempt: i64 = 0;
    while (attempt < attempts) : (attempt += 1) {
        var tortoise = seed;
        var hare = seed;
        var iteration: i64 = 0;
        while (iteration < step_limit) : (iteration += 1) {
            tortoise = advance(tortoise, step, num);
            hare = advance(advance(hare, step, num), step, num);
            const difference = if (hare >= tortoise) hare - tortoise else tortoise - hare;
            const divisor = gcdNonnegative(difference, num);
            if (divisor == 1) continue;
            if (divisor < num) return divisor;
            break;
        }
        seed = hare;
        step += 1;
    }
    return 0;
}
