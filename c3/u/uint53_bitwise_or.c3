module uint53_bitwise_or;

fn long uint53_bitwise_or(ulong left, ulong right) @export("uint53_bitwise_or") {
    ulong max_uint53 = 9007199254740991;
    if (left > max_uint53 || right > max_uint53) return -1;
    ulong result = 0;
    ulong bit = 1;
    while (left != 0 && right != 0) {
        ulong left_bit = left % 2;
        ulong right_bit = right % 2;
        result += (1 - (1 - left_bit) * (1 - right_bit)) * bit;
        left = (left - left_bit) / 2;
        right = (right - right_bit) / 2;
        bit *= 2;
    }
    return (long)(result + (left + right) * bit);
}
