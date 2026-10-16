module uint53_xor;

const MAX_UINT53 = 9007199254740991;

// Iterative bitwise XOR for two nonnegative uint53 operands.
fn long uint53_xor(long left, long right) @export("uint53_xor") {
    if (left < 0 || left > MAX_UINT53 || right < 0 || right > MAX_UINT53) return -1;
    long result = 0;
    long bit = 1;
    while (left != 0 && right != 0) {
        long left_bit = left % 2;
        long right_bit = right % 2;
        result += ((left_bit + right_bit) % 2) * bit;
        left = (left - left_bit) / 2;
        right = (right - right_bit) / 2;
        bit *= 2;
    }
    return result + (left + right) * bit;
}
