const FIELD: i32 = 7;
const MAX_N: usize = 7;
const MAX_POLYNOMIAL: usize = 16;
const MAX_INPUT_LENGTH: usize = 11;

const Polynomial = struct {
    coefficients: [MAX_POLYNOMIAL]i32,
    length: usize,
};

const DivisionResult = struct {
    quotient: Polynomial,
    remainder: Polynomial,
};

const Interpolation = struct {
    vanishing: Polynomial,
    interpolant: Polynomial,
};

fn normalize(value: i32) i32 {
    return @mod(value, FIELD);
}

fn zeroPolynomial() Polynomial {
    return .{ .coefficients = @splat(0), .length = 1 };
}

fn constantPolynomial(value: i32) Polynomial {
    var result = zeroPolynomial();
    result.coefficients[0] = normalize(value);
    return result;
}

fn trim(polynomial: *Polynomial) void {
    while (polynomial.length > 1 and polynomial.coefficients[polynomial.length - 1] == 0) {
        polynomial.length -= 1;
    }
}

fn isZero(polynomial: Polynomial) bool {
    return polynomial.length == 1 and polynomial.coefficients[0] == 0;
}

fn multiplyLinear(polynomial: Polynomial, root: i32) Polynomial {
    var result = zeroPolynomial();
    result.length = polynomial.length + 1;
    for (0..polynomial.length) |degree| {
        result.coefficients[degree] = normalize(result.coefficients[degree] - root * polynomial.coefficients[degree]);
        result.coefficients[degree + 1] = normalize(result.coefficients[degree + 1] + polynomial.coefficients[degree]);
    }
    trim(&result);
    return result;
}

fn addScaled(target: Polynomial, source: Polynomial, scale: i32) Polynomial {
    var result = target;
    result.length = @max(result.length, source.length);
    for (0..source.length) |degree| {
        result.coefficients[degree] = normalize(result.coefficients[degree] + scale * source.coefficients[degree]);
    }
    trim(&result);
    return result;
}

fn multiply(left: Polynomial, right: Polynomial) Polynomial {
    var result = zeroPolynomial();
    result.length = left.length + right.length - 1;
    for (0..left.length) |i| {
        for (0..right.length) |j| {
            result.coefficients[i + j] = normalize(result.coefficients[i + j] + left.coefficients[i] * right.coefficients[j]);
        }
    }
    trim(&result);
    return result;
}

fn divideWithRemainder(numerator: Polynomial, denominator: Polynomial) ?DivisionResult {
    const inverse = [7]i32{ 0, 1, 4, 5, 2, 3, 6 };
    if (isZero(denominator)) return null;
    var result = DivisionResult{ .quotient = zeroPolynomial(), .remainder = numerator };
    var divisor = denominator;
    trim(&result.remainder);
    trim(&divisor);
    const inverse_lead = inverse[@intCast(divisor.coefficients[divisor.length - 1])];
    while (!isZero(result.remainder) and result.remainder.length >= divisor.length) {
        const shift = result.remainder.length - divisor.length;
        const factor = normalize(result.remainder.coefficients[result.remainder.length - 1] * inverse_lead);
        result.quotient.length = @max(result.quotient.length, shift + 1);
        result.quotient.coefficients[shift] = normalize(result.quotient.coefficients[shift] + factor);
        for (0..divisor.length) |degree| {
            result.remainder.coefficients[shift + degree] = normalize(
                result.remainder.coefficients[shift + degree] - factor * divisor.coefficients[degree],
            );
        }
        trim(&result.remainder);
    }
    trim(&result.quotient);
    return result;
}

fn interpolate(n: usize, received: *const [MAX_N]i32) Interpolation {
    const inverse = [7]i32{ 0, 1, 4, 5, 2, 3, 6 };
    var result = Interpolation{
        .vanishing = constantPolynomial(1),
        .interpolant = zeroPolynomial(),
    };
    for (0..n) |point| result.vanishing = multiplyLinear(result.vanishing, @intCast(point));
    for (0..n) |i| {
        var basis = constantPolynomial(1);
        var denominator: i32 = 1;
        for (0..n) |j| {
            if (i == j) continue;
            basis = multiplyLinear(basis, @intCast(j));
            denominator = normalize(denominator * (@as(i32, @intCast(i)) - @as(i32, @intCast(j))));
        }
        const scale = normalize(received[i] * inverse[@intCast(denominator)]);
        result.interpolant = addScaled(result.interpolant, basis, scale);
    }
    return result;
}

fn decode(n: usize, k: usize, error_limit: usize, received: *const [MAX_N]i32) i64 {
    const data = interpolate(n, received);
    if (isZero(data.interpolant)) return 1;

    var remainder_previous = data.vanishing;
    var remainder_current = data.interpolant;
    var bezout_previous = zeroPolynomial();
    var bezout_current = constantPolynomial(1);
    const threshold = @divTrunc(n + k - 1, 2);
    while (!isZero(remainder_current) and remainder_current.length - 1 > threshold) {
        const division = divideWithRemainder(remainder_previous, remainder_current) orelse return 0;
        const bezout_next = addScaled(bezout_previous, multiply(division.quotient, bezout_current), -1);
        remainder_previous = remainder_current;
        remainder_current = division.remainder;
        bezout_previous = bezout_current;
        bezout_current = bezout_next;
    }
    if (isZero(remainder_current) or isZero(bezout_current)) return 0;

    const division = divideWithRemainder(remainder_current, bezout_current) orelse return 0;
    if (!isZero(division.remainder)) return 0;
    var message = division.quotient;
    trim(&message);
    if (message.length > k) return 0;

    var mismatches: usize = 0;
    for (0..n) |x_index| {
        const x: i32 = @intCast(x_index);
        var value: i32 = 0;
        var degree = message.length;
        while (degree > 0) {
            degree -= 1;
            value = @rem(value * x + message.coefficients[degree], FIELD);
        }
        if (value != received[x_index]) mismatches += 1;
    }
    if (mismatches > error_limit) return 0;

    var encoded: i64 = 1;
    var place: i64 = 1;
    for (0..k) |degree| {
        if (degree < message.length) {
            encoded += @as(i64, @intCast(message.coefficients[degree])) * place;
        }
        place *= @as(i64, FIELD);
    }
    return encoded;
}

export fn gao_rs_decode(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    const n_value = input[0];
    const k_value = input[1];
    const error_value = input[2];
    if (n_value < 2 or n_value > 7 or k_value < 1 or k_value > 3
        or k_value > n_value or error_value < 0 or error_value > 2) return -1;
    const n: usize = @intCast(n_value);
    const k: usize = @intCast(k_value);
    const error_limit: usize = @intCast(error_value);
    if (2 * error_limit > n - k or length != 3 + n) return -1;

    var received: [MAX_N]i32 = @splat(0);
    for (0..n) |index| {
        const symbol = input[3 + index];
        if (symbol < 0 or symbol >= @as(i64, FIELD)) return -1;
        received[index] = @intCast(symbol);
    }
    return decode(n, k, error_limit, &received);
}
