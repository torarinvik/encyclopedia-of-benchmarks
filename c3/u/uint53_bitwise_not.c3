module uint53_bitwise_not;

const long MAX_UINT53 = 9007199254740991;
const long TWO_TO_53 = 9007199254740992;

// Complement every bit in the fixed-width unsigned 53-bit domain.
fn long uint53_bitwise_not(long n) @export("uint53_bitwise_not") {
    if (n < 0 || n > MAX_UINT53) return -1;

    long result = 0;
    long bit = 1;
    while (n >= 255) {
        long byte = n % 256;
        result += (255 - byte) * bit;
        n = (n - byte) / 256;
        bit *= 256;
    }
    while (n != 0) {
        long n_bit = n % 2;
        result += (1 - n_bit) * bit;
        n = (n - n_bit) / 2;
        bit *= 2;
    }

    return TWO_TO_53 - bit + result;
}
