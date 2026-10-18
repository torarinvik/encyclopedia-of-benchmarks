const INVALID_RESULT: i64 = -1;
const MAX_INPUT_LENGTH: usize = 69;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const LOW_63_MASK: u64 = 0x7fff_ffff_ffff_ffff;

fn powerMod(base: i64, exponent_input: i64, modulus: i64) i64 {
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

fn hashU32(hash_input: u64, value: i64) u64 {
    var hash = hash_input;
    const bits: u32 = @intCast(value);
    for (0..4) |byte| {
        const shift: u5 = @intCast(byte * 8);
        hash = (hash ^ @as(u64, @intCast((bits >> shift) & 255))) *% FNV_PRIME;
    }
    return hash;
}

export fn rsa_explicit_key_transform(packed: ?[*]const i64, length: usize) i64 {
    const values = packed orelse return INVALID_RESULT;
    if (length < 5 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const modulus = values[0];
    const public_exponent = values[1];
    const private_exponent = values[2];
    const message_length = values[3];
    if (modulus < 128 or modulus > 55295 or public_exponent < 1 or public_exponent > 1000000 or
        private_exponent < 1 or private_exponent > 1000000 or message_length < 1 or message_length > 64 or
        length != @as(usize, @intCast(4 + message_length))) return INVALID_RESULT;
    const count: usize = @intCast(message_length);
    for (0..count) |i| {
        const value = values[4 + i];
        if (value < 0 or value > 127 or value >= modulus) return INVALID_RESULT;
    }
    var hash = FNV_OFFSET_BASIS;
    for (0..count) |i| hash = hashU32(hash, powerMod(values[4 + i], public_exponent, modulus));
    for (0..count) |i| {
        const ciphertext = powerMod(values[4 + i], public_exponent, modulus);
        hash = hashU32(hash, powerMod(ciphertext, private_exponent, modulus));
    }
    return @intCast(hash & LOW_63_MASK);
}
