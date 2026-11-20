fn gcdI64(a_input: i64, b_input: i64) i64 {
    var a = a_input;
    var b = b_input;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn powModI64(base_input: i64, exponent_input: i64, modulus: i64) i64 {
    var base = @rem(base_input, modulus);
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn totientI64(value: i64) i64 {
    var remaining = value;
    var result = value;
    var prime: i64 = 2;
    while (prime * prime <= remaining) : (prime += 1) {
        if (@rem(remaining, prime) == 0) {
            result = @divTrunc(result, prime) * (prime - 1);
            while (@rem(remaining, prime) == 0) remaining = @divTrunc(remaining, prime);
        }
    }
    if (remaining > 1) result = @divTrunc(result, remaining) * (remaining - 1);
    return result;
}

fn reduceOrder(base: i64, modulus: i64, initial_order: i64) i64 {
    var remaining = initial_order;
    var order = initial_order;
    var prime: i64 = 2;
    while (prime * prime <= remaining) : (prime += 1) {
        if (@rem(remaining, prime) == 0) {
            while (@rem(remaining, prime) == 0) remaining = @divTrunc(remaining, prime);
            while (@rem(order, prime) == 0 and powModI64(base, @divTrunc(order, prime), modulus) == 1)
                order = @divTrunc(order, prime);
        }
    }
    if (remaining > 1) {
        while (@rem(order, remaining) == 0 and powModI64(base, @divTrunc(order, remaining), modulus) == 1)
            order = @divTrunc(order, remaining);
    }
    return order;
}

export fn multiplicative_order(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..length];
    const base = values[0];
    const modulus = values[1];
    if (modulus < 2 or modulus > 1000 or base < 0 or base >= modulus) return -1;
    if (gcdI64(base, modulus) != 1) return 0;
    return reduceOrder(base, modulus, totientI64(modulus));
}
