const INVALID_RESULT: i64 = -1;
const MAX_INPUT_LENGTH: usize = 69;
const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const LOW_63_MASK: u64 = 0x7fff_ffff_ffff_ffff;

fn boundedPower(base: i64, exponent: i64) i64 {
    var result: i64 = 1;
    var i: i64 = 0;
    while (i < exponent) : (i += 1) result *= base;
    return result;
}

fn hashByte(hash_input: u64, value: u8) u64 {
    return (hash_input ^ @as(u64, value)) *% FNV_PRIME;
}

export fn rsa_ruby_byte_chunk(packed: ?[*]const i64, length: usize) i64 {
    const values = packed orelse return INVALID_RESULT;
    if (length < 5 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const modulus = values[0];
    const public_exponent = values[1];
    const private_exponent = values[2];
    const message_length = values[3];
    if (modulus != 33 or public_exponent < 1 or public_exponent > 7 or private_exponent < 1 or
        private_exponent > 7 or message_length < 1 or message_length > 64 or
        length != @as(usize, @intCast(4 + message_length))) return INVALID_RESULT;
    const count: usize = @intCast(message_length);
    var ciphertexts: [64]i64 = undefined;
    for (0..count) |i| {
        const value = values[4 + i];
        if (value < 0 or value >= modulus) return INVALID_RESULT;
        ciphertexts[i] = @rem(boundedPower(value, public_exponent), modulus);
    }
    var hash = FNV_OFFSET_BASIS;
    for (0..count) |i| {
        const value = ciphertexts[i];
        hash = hashByte(hash, @intCast('0' + @divTrunc(value, 10)));
        hash = hashByte(hash, @intCast('0' + @rem(value, 10)));
    }
    for (0..count) |i| {
        const recovered = @rem(boundedPower(ciphertexts[i], private_exponent), modulus);
        hash = hashByte(hash, @intCast(recovered));
    }
    return @intCast(hash & LOW_63_MASK);
}
