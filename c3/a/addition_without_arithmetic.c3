module addition_without_arithmetic;

fn long signed_sum_from_bits(uint bits)
{
    if (bits <= 2147483647) return (long)bits;
    return (long)bits - 4294967296;
}

fn long addition_without_arithmetic(ulong left_encoded, ulong right_encoded) @export("addition_without_arithmetic")
{
    if ((left_encoded > 0x7FFF_FFFF && left_encoded < 0xFFFF_FFFF_8000_0000)
            || (right_encoded > 0x7FFF_FFFF && right_encoded < 0xFFFF_FFFF_8000_0000)) return -1;
    long left_value = signed_sum_from_bits((uint)left_encoded);
    long right_value = signed_sum_from_bits((uint)right_encoded);
    uint left = (uint)left_encoded;
    uint right = (uint)right_encoded;
    while (right != 0) {
        uint carry = left & right;
        left ^= right;
        right = carry << 1;
    }
    long result = signed_sum_from_bits(left);
    if ((left_value < 0) == (right_value < 0) && (result < 0) != (left_value < 0)) return -1;
    return result;
}
