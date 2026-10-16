fn gcd(a_value: u64, b_value: u64) u64 {
    var a = a_value;
    var b = b_value;
    while (b != 0) {
        const remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

fn addMod(a: u64, b: u64, modulus: u64) u64 {
    return if (a >= modulus - b) a - (modulus - b) else a + b;
}

fn mulMod(a_value: u64, b_value: u64, modulus: u64) u64 {
    var a = a_value % modulus;
    var b = b_value;
    var result: u64 = 0;
    while (b != 0) {
        if (b & 1 != 0) result = addMod(result, a, modulus);
        b >>= 1;
        if (b != 0) a = addMod(a, a, modulus);
    }
    return result;
}

fn inverseMod(value: u64, modulus: u64) u64 {
    var old_r = modulus;
    var r = value % modulus;
    var old_t: u64 = 0;
    var t: u64 = 1;
    while (r != 0) {
        const quotient = old_r / r;
        const next_r = old_r % r;
        const product = mulMod(quotient % modulus, t, modulus);
        const next_t = if (old_t >= product) old_t - product else modulus - (product - old_t);
        old_r = r;
        r = next_r;
        old_t = t;
        t = next_t;
    }
    return old_t;
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn merkle_hellman_cryptosystem(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 12 or length > 43) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > 127 or values[10] < 1 or values[10] > 32) return -1;
    const draw_count: usize = @intCast(values[10]);
    if (length != 11 + draw_count) return -1;

    var easy: [8]u64 = undefined;
    var sum: u64 = 1 << 32;
    for (0..8) |index| {
        if (values[1 + index] < 0 or values[1 + index] > 4294967295) return -1;
        easy[index] = sum + @as(u64, @intCast(values[1 + index]));
        sum += easy[index];
    }
    if (values[9] < 0 or values[9] > 4294967295) return -1;
    const modulus = sum + @as(u64, @intCast(values[9]));
    for (0..draw_count) |index| {
        const draw_value = values[11 + index];
        if (draw_value < 0 or @as(u64, @intCast(draw_value)) > modulus) return -1;
        const divisor = gcd(@intCast(draw_value), modulus);
        if (index + 1 < draw_count and divisor == 1) return -1;
        if (index + 1 == draw_count and divisor != 1) return -1;
    }
    if (output == null or capacity < 17) return -2;

    const multiplier: u64 = @intCast(values[10 + draw_count]);
    var hard: [8]u64 = undefined;
    for (0..8) |index| hard[index] = mulMod(multiplier, easy[index], modulus);
    const message: u64 = @intCast(values[0]);
    var ciphertext: u64 = 0;
    var bit_index: i32 = 7;
    while (bit_index >= 0) : (bit_index -= 1) {
        if ((message >> @intCast(bit_index)) & 1 != 0)
            ciphertext += hard[@intCast(7 - bit_index)];
    }

    const inverse = inverseMod(multiplier, modulus);
    var residue = mulMod(inverse, ciphertext % modulus, modulus);
    var decoded: u8 = 0;
    for (0..8) |index| {
        const weight = easy[7 - index];
        if (residue >= weight) {
            residue -= weight;
            decoded |= @as(u8, 1) << @intCast(index);
        }
    }
    if (residue != 0 or decoded != message) return -1;
    const out = output.?;
    putI64(out, 0, @intCast(ciphertext));
    putI64(out, 8, 1);
    out[16] = decoded;
    return 17;
}
