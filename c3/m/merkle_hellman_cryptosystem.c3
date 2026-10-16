module merkle_hellman_cryptosystem;

fn ulong gcd_u64(ulong a, ulong b) {
    while (b != 0) {
        ulong remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

fn ulong add_mod(ulong a, ulong b, ulong modulus) {
    return a >= modulus - b ? a - (modulus - b) : a + b;
}

fn ulong mul_mod(ulong a, ulong b, ulong modulus) {
    ulong result = 0;
    a %= modulus;
    while (b != 0) {
        if ((b & 1) != 0) result = add_mod(result, a, modulus);
        b >>= 1;
        if (b != 0) a = add_mod(a, a, modulus);
    }
    return result;
}

fn ulong inverse_mod(ulong value, ulong modulus) {
    ulong old_r = modulus, r = value % modulus;
    ulong old_t = 0, t = 1;
    while (r != 0) {
        ulong quotient = old_r / r;
        ulong next_r = old_r % r;
        ulong product = mul_mod(quotient % modulus, t, modulus);
        ulong next_t = old_t >= product ? old_t - product : modulus - (product - old_t);
        old_r = r;
        r = next_r;
        old_t = t;
        t = next_t;
    }
    return old_t;
}

fn void put_i64(long value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; ++byte)
        output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long merkle_hellman_cryptosystem(long* input, usz length, char* output, usz capacity)
    @export("merkle_hellman_cryptosystem") {
    if (input == null || length < 12 || length > 43) return -1;
    if (input[0] < 0 || input[0] > 127 || input[10] < 1 || input[10] > 32) return -1;
    usz draw_count = (usz)input[10];
    if (length != 11 + draw_count) return -1;

    ulong[8] easy;
    ulong sum = 4294967296ul;
    for (usz index = 0; index < 8; ++index) {
        if (input[1 + index] < 0 || input[1 + index] > 4294967295) return -1;
        easy[index] = sum + (ulong)input[1 + index];
        sum += easy[index];
    }
    if (input[9] < 0 || input[9] > 4294967295) return -1;
    ulong modulus = sum + (ulong)input[9];
    for (usz index = 0; index < draw_count; ++index) {
        long draw_value = input[11 + index];
        if (draw_value < 0 || (ulong)draw_value > modulus) return -1;
        ulong divisor = gcd_u64((ulong)draw_value, modulus);
        if (index + 1 < draw_count && divisor == 1) return -1;
        if (index + 1 == draw_count && divisor != 1) return -1;
    }
    if (output == null || capacity < 17) return -2;

    ulong multiplier = (ulong)input[10 + draw_count];
    ulong[8] hard;
    for (usz index = 0; index < 8; ++index)
        hard[index] = mul_mod(multiplier, easy[index], modulus);
    ulong message = (ulong)input[0];
    ulong ciphertext = 0;
    for (int bit_index = 7; bit_index >= 0; --bit_index) {
        if (((message >> bit_index) & 1) != 0)
            ciphertext += hard[7 - (usz)bit_index];
    }

    ulong inverse = inverse_mod(multiplier, modulus);
    ulong residue = mul_mod(inverse, ciphertext % modulus, modulus);
    uint8 decoded = 0;
    for (usz index = 0; index < 8; ++index) {
        ulong weight = easy[7 - index];
        if (residue >= weight) {
            residue -= weight;
            decoded |= (uint8)(1 << index);
        }
    }
    if (residue != 0 || decoded != (uint8)message) return -1;
    put_i64((long)ciphertext, output, 0);
    put_i64(1, output, 8);
    output[16] = (char)decoded;
    return 17;
}
