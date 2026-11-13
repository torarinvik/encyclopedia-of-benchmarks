const STAGE1_PRIMES = [_]i64{ 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31 };

const XPoint = struct {
    x: i64,
    z: i64,
};

fn modNorm(value_input: i64, modulus: i64) i64 {
    const remainder = @rem(value_input, modulus);
    return if (remainder < 0) remainder + modulus else remainder;
}

fn gcdI64(left_input: i64, right_input: i64) i64 {
    var left = if (left_input < 0) -left_input else left_input;
    var right = if (right_input < 0) -right_input else right_input;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn squareFree(number: i64) bool {
    var divisor: i64 = 2;
    while (divisor * divisor <= number) : (divisor += 1) {
        if (@rem(number, divisor * divisor) == 0) return false;
    }
    return true;
}

fn xDouble(point: XPoint, a24: i64, modulus: i64) XPoint {
    const plus = modNorm(point.x + point.z, modulus);
    const minus = modNorm(point.x - point.z, modulus);
    const plus_sq = @rem(plus * plus, modulus);
    const minus_sq = @rem(minus * minus, modulus);
    const delta = modNorm(plus_sq - minus_sq, modulus);
    return .{
        .x = @rem(plus_sq * minus_sq, modulus),
        .z = @rem(delta * modNorm(minus_sq + a24 * delta, modulus), modulus),
    };
}

fn xAdd(left: XPoint, right: XPoint, difference: XPoint, modulus: i64) XPoint {
    const first = @rem(modNorm(left.x - left.z, modulus) * modNorm(right.x + right.z, modulus), modulus);
    const second = @rem(modNorm(left.x + left.z, modulus) * modNorm(right.x - right.z, modulus), modulus);
    const sum_term = modNorm(first + second, modulus);
    const difference_term = modNorm(first - second, modulus);
    return .{
        .x = @rem(@rem(difference.z * sum_term, modulus) * sum_term, modulus),
        .z = @rem(@rem(difference.x * difference_term, modulus) * difference_term, modulus),
    };
}

fn xMultiply(point: XPoint, scalar: i64, a24: i64, modulus: i64) XPoint {
    var r0 = XPoint{ .x = 1, .z = 0 };
    var r1 = point;
    var copy = scalar;
    var highest: i32 = 0;
    while (copy > 1) : (highest += 1) copy = @divTrunc(copy, 2);
    var bit = highest;
    while (bit >= 0) : (bit -= 1) {
        if (@rem(@divTrunc(scalar, @as(i64, 1) << @intCast(bit)), 2) != 0) {
            r0 = xAdd(r0, r1, point, modulus);
            r1 = xDouble(r1, a24, modulus);
        } else {
            r1 = xAdd(r0, r1, point, modulus);
            r0 = xDouble(r0, a24, modulus);
        }
    }
    return r0;
}

export fn elliptic_curve_method_stage1(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 5) return -1;
    const values = input.?[0..length];
    const number = values[0];
    const curve_a = values[1];
    const point_x = values[2];
    const point_y = values[3];
    const bound = values[4];
    if (number < 3 or number > 10_000 or @rem(number, 2) == 0 or bound < 2 or bound > 32) return -1;
    if (curve_a < 0 or curve_a >= number or point_x < 0 or point_x >= number or point_y < 0 or point_y >= number) return -1;
    if (!squareFree(number) or gcdI64(curve_a * curve_a - 4, number) != 1) return -1;
    const x_sq = @rem(point_x * point_x, number);
    const rhs = @rem(x_sq * point_x + curve_a * x_sq + point_x, number);
    if (@rem(point_y * point_y, number) != rhs) return -1;
    const inverse_four = if (@rem(number, 4) == 3) @divTrunc(number + 1, 4) else @divTrunc(3 * number + 1, 4);
    const a24 = @rem((curve_a + 2) * inverse_four, number);
    var point = XPoint{ .x = point_x, .z = 1 };
    for (STAGE1_PRIMES) |prime| {
        if (prime > bound) break;
        var prime_power = prime;
        while (prime_power <= @divTrunc(bound, prime)) : (prime_power *= prime) {}
        point = xMultiply(point, prime_power, a24, number);
        const divisor = gcdI64(point.z, number);
        if (divisor > 1) return if (divisor < number) 1 else 0;
    }
    return 0;
}
