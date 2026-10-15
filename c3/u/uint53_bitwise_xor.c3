module uint53_bitwise_xor;

const ulong MAX_UINT53 = 9007199254740991;
const long INVALID_RESULT = -1;

// XOR two values in the bounded unsigned 53-bit domain.
fn long uint53_bitwise_xor(ulong n, ulong m) @export("uint53_bitwise_xor") {
    if (n > MAX_UINT53 || m > MAX_UINT53) return INVALID_RESULT;

    ulong result = 0;
    ulong bit = 1;
    while (n != 0 && m != 0) {
        ulong n_bit = n % 2;
        ulong m_bit = m % 2;
        result += ((n_bit + m_bit) % 2) * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    return (long)(result + (n + m) * bit);
}
