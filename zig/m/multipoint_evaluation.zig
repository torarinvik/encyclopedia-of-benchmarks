const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_M: usize = 8;
const LEAF_BASE: usize = 8;
const NODE_CAPACITY: usize = 16;
const COEFFICIENT_CAPACITY: usize = 9;
const MAX_INPUT: usize = 18;
const Polynomial = [COEFFICIENT_CAPACITY]i64;

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

fn trim(polynomial: Polynomial, initial_length: usize) usize {
    var length = initial_length;
    while (length > 1 and polynomial[length - 1] == 0) length -= 1;
    return length;
}

fn multiply(left: Polynomial, left_length: usize, right: Polynomial,
    right_length: usize, product: *Polynomial) usize {
    const length = left_length + right_length - 1;
    @memset(product, 0);
    for (0..left_length) |i| {
        for (0..right_length) |j| {
            product.*[i + j] = @rem(product.*[i + j] + left[i] * right[j], MODULUS);
        }
    }
    return length;
}

fn remainder(dividend: Polynomial, dividend_length: usize, divisor: Polynomial,
    divisor_length: usize, result: *Polynomial) usize {
    @memset(result, 0);
    if (divisor_length == 1 and divisor[0] == 1) return 1;
    for (0..dividend_length) |i| result.*[i] = dividend[i];
    var length = trim(result.*, dividend_length);
    while (length >= divisor_length) {
        const shift = length - divisor_length;
        const factor = result.*[length - 1];
        for (0..divisor_length) |degree| {
            const slot = shift + degree;
            result.*[slot] = @rem(result.*[slot] - factor * divisor[degree], MODULUS);
            if (result.*[slot] < 0) result.*[slot] += MODULUS;
        }
        length = trim(result.*, length);
    }
    return length;
}

export fn multipoint_evaluation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or
        input[1] < 1 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;
    for (0..n + m) |i| if (input[2 + i] < 0 or input[2 + i] >= MODULUS) return -1;
    if (input[1 + n] == 0) return -1;
    const bytes = 8 * m;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;

    var products = [_]Polynomial{[_]i64{0} ** COEFFICIENT_CAPACITY} ** NODE_CAPACITY;
    var remainders = [_]Polynomial{[_]i64{0} ** COEFFICIENT_CAPACITY} ** NODE_CAPACITY;
    var product_lengths = [_]usize{0} ** NODE_CAPACITY;
    var remainder_lengths = [_]usize{0} ** NODE_CAPACITY;
    var starts = [_]usize{0} ** NODE_CAPACITY;
    var spans = [_]usize{0} ** NODE_CAPACITY;
    for (1..NODE_CAPACITY) |node| {
        products[node][0] = 1;
        product_lengths[node] = 1;
    }
    for (0..m) |i| {
        const leaf = LEAF_BASE + i;
        products[leaf][0] = if (input[2 + n + i] == 0) 0 else MODULUS - input[2 + n + i];
        products[leaf][1] = 1;
        product_lengths[leaf] = 2;
    }
    var node = LEAF_BASE - 1;
    while (node > 0) : (node -= 1) {
        product_lengths[node] = multiply(products[2 * node], product_lengths[2 * node],
            products[2 * node + 1], product_lengths[2 * node + 1], &products[node]);
    }
    starts[1] = 0;
    spans[1] = LEAF_BASE;
    for (1..LEAF_BASE) |parent| {
        spans[2 * parent] = spans[parent] / 2;
        spans[2 * parent + 1] = spans[parent] / 2;
        starts[2 * parent] = starts[parent];
        starts[2 * parent + 1] = starts[parent] + spans[parent] / 2;
    }
    var input_poly: Polynomial = [_]i64{0} ** COEFFICIENT_CAPACITY;
    for (0..n) |i| input_poly[i] = input[2 + i];
    remainder_lengths[1] = remainder(input_poly, n, products[1], product_lengths[1], &remainders[1]);
    for (1..LEAF_BASE) |parent| {
        for (0..2) |side| {
            const child = 2 * parent + side;
            if (starts[child] < m) {
                remainder_lengths[child] = remainder(remainders[parent], remainder_lengths[parent],
                    products[child], product_lengths[child], &remainders[child]);
            }
        }
    }
    for (0..m) |i| storeLe(output, 8 * i, remainders[LEAF_BASE + i][0]);
    return @intCast(bytes);
}
