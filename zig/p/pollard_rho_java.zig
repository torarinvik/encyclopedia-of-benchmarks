const std = @import("std");

const MIN_N: i64 = 2;
const MAX_N: i64 = 46_340;
const MAX_STEPS: i64 = 4_096;

fn javaRemainder(value: i64, modulus: i64) i64 {
    return if (value < 0) -@rem(-value, modulus) else @rem(value, modulus);
}

fn nextValue(value: i64, modulus: i64) i64 {
    return javaRemainder(value * value - 1, modulus);
}

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

export fn pollard_rho_java(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?;
    const n = values[0];
    const step_limit = values[1];
    if (n < MIN_N or n > MAX_N or step_limit < 1 or step_limit > MAX_STEPS) return -1;

    var x: i64 = 2;
    var y: i64 = 2;
    var step: i64 = 0;
    while (step < step_limit) : (step += 1) {
        x = nextValue(x, n);
        y = nextValue(nextValue(y, n), n);
        const difference = if (x >= y) x - y else y - x;
        const divisor = gcdNonnegative(difference, n);
        if (divisor == 1) continue;
        return if (divisor == n) 0 else divisor;
    }
    return -2;
}
