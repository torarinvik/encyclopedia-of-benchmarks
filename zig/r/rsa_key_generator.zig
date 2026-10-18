const INVALID_RESULT: i64 = -1;
const MIN_KEY_SIZE: i64 = 2;
const MAX_KEY_SIZE: i64 = 20;
const MAX_DRAWS: i64 = 1024;
const MAX_PACKED_LENGTH: usize = 1027;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const LOW_63_MASK: u64 = 0x7fffffffffffffff;

const DrawState = struct {
    values: [*]const i64,
    length: usize,
    cursor: usize,
    key_size: i64,
};

fn nextDraw(state: *DrawState, low: i64, high: i64) ?i64 {
    if (state.cursor >= state.length) return null;
    const value = state.values[state.cursor];
    state.cursor += 1;
    if (value < low or value >= high) return null;
    return value;
}

fn gcdI64(a_input: i64, b_input: i64) i64 {
    var a = a_input;
    var b = b_input;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return if (a < 0) -a else a;
}

fn powerModI64(base: i64, exponent_input: i64, modulus: i64) i64 {
    var exponent = exponent_input;
    var result: i64 = 1;
    var power = @rem(base, modulus);
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * power, modulus);
        power = @rem(power * power, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn rabinMiller(num: i64, state: *DrawState) ?bool {
    var s = num - 1;
    var t: i64 = 0;
    while (@rem(s, 2) == 0) {
        s = @divTrunc(s, 2);
        t += 1;
    }
    for (0..5) |_| {
        const base = nextDraw(state, 2, num - 1) orelse return null;
        var value = powerModI64(base, s, num);
        if (value != 1) {
            var i: i64 = 0;
            while (value != num - 1) {
                if (i == t - 1) return false;
                i += 1;
                value = @rem(value * value, num);
            }
        }
    }
    return true;
}

fn isPrimeLowNum(num: i64, state: *DrawState) ?bool {
    if (num < 2) return false;
    if (num <= 997) {
        var divisor: i64 = 2;
        while (divisor * divisor <= num) : (divisor += 1) {
            if (@rem(num, divisor) == 0) return false;
        }
        return true;
    }
    var divisor: i64 = 2;
    while (divisor <= 997) : (divisor += 1) {
        if (@rem(num, divisor) == 0) return false;
    }
    return rabinMiller(num, state);
}

fn generateLargePrime(state: *DrawState) ?i64 {
    const low: i64 = @as(i64, 1) << @intCast(state.key_size - 1);
    const high: i64 = @as(i64, 1) << @intCast(state.key_size);
    while (true) {
        const candidate = nextDraw(state, low, high) orelse return null;
        const is_prime = (isPrimeLowNum(candidate, state) orelse return null);
        if (is_prime) return candidate;
    }
}

fn findModInverse(a: i64, modulus: i64) i64 {
    if (gcdI64(a, modulus) != 1) return INVALID_RESULT;
    var u1: i64 = 1;
    var u2: i64 = 0;
    var u3 = a;
    var v1: i64 = 0;
    var v2: i64 = 1;
    var v3 = modulus;
    while (v3 != 0) {
        const quotient = @divTrunc(u3, v3);
        const next_v1 = u1 - quotient * v1;
        const next_v2 = u2 - quotient * v2;
        const next_v3 = u3 - quotient * v3;
        u1 = v1;
        u2 = v2;
        u3 = v3;
        v1 = next_v1;
        v2 = next_v2;
        v3 = next_v3;
    }
    return @rem(u1, modulus);
}

fn hashI64(hash_input: u64, value: i64) u64 {
    var hash = hash_input;
    const bits: u64 = @intCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        hash = (hash ^ ((bits >> shift) & 255)) *% FNV_PRIME;
    }
    return hash;
}

export fn rsa_key_generator(packed: ?[*]const i64, length: usize) i64 {
    const values = packed orelse return INVALID_RESULT;
    if (length < 2 or length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const key_size = values[0];
    const draw_count = values[1];
    if (key_size < MIN_KEY_SIZE or key_size > MAX_KEY_SIZE or draw_count < 0 or draw_count > MAX_DRAWS or
        length != @as(usize, @intCast(2 + draw_count))) return INVALID_RESULT;
    const draw_limit: i64 = @as(i64, 1) << @intCast(key_size);
    const count: usize = @intCast(draw_count);
    for (0..count) |i| {
        const value = values[2 + i];
        if (value < 2 or value >= draw_limit) return INVALID_RESULT;
    }

    var state = DrawState{ .values = values, .length = length, .cursor = 2, .key_size = key_size };
    const p = generateLargePrime(&state) orelse return INVALID_RESULT;
    const q = generateLargePrime(&state) orelse return INVALID_RESULT;
    const n = p * q;
    const phi = (p - 1) * (q - 1);
    const low: i64 = @as(i64, 1) << @intCast(key_size - 1);
    const high: i64 = @as(i64, 1) << @intCast(key_size);
    var e: i64 = undefined;
    while (true) {
        e = nextDraw(&state, low, high) orelse return INVALID_RESULT;
        if (gcdI64(e, phi) == 1) break;
    }
    const d = findModInverse(e, phi);
    var hash = FNV_OFFSET_BASIS;
    hash = hashI64(hash, n);
    hash = hashI64(hash, e);
    hash = hashI64(hash, n);
    hash = hashI64(hash, d);
    return @intCast(hash & LOW_63_MASK);
}
