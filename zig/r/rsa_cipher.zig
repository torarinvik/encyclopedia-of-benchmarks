export fn rsa_cipher_encrypt_ascii(values: ?[*]const i64, length: usize) i64 {
    const input = values orelse return -1;
    if (length != 3) return -1;
    const ascii_code = input[0];
    const exponent_input = input[1];
    const modulus_input = input[2];
    if (ascii_code < 0 or ascii_code > 127 or modulus_input < 128 or modulus_input > 65535 or
        exponent_input < 1 or exponent_input >= modulus_input) return -1;

    var base: u64 = @intCast(ascii_code);
    var exponent: u64 = @intCast(exponent_input);
    const modulus: u64 = @intCast(modulus_input);
    var result: u64 = 1;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 == 1) result = (result * base) % modulus;
        exponent >>= 1;
        base = (base * base) % modulus;
    }
    return @intCast(result);
}
