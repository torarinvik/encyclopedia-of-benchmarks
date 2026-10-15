module uint53_bitwise_and;

fn long uint53_bitwise_and(long n, long m) @export("uint53_bitwise_and") {
    if (n < 0 || m < 0 || n > 9007199254740991 || m > 9007199254740991) return -1;
    long result = 0;
    long bit = 1;
    while (n != 0 && m != 0) {
        long n_bit = n % 2;
        long m_bit = m % 2;
        result += n_bit * m_bit * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    return result;
}
