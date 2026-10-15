fn signed_sum_from_bits(bits: u32) i64 {
    if (bits <= 2_147_483_647) return @as(i64, bits);
    return @as(i64, bits) - 4_294_967_296;
}

const min_i32_encoding: u64 = 0xFFFF_FFFF_8000_0000;

fn is_signed_i32_encoding(value: u64) bool {
    return value <= 2_147_483_647 or value >= min_i32_encoding;
}

export fn addition_without_arithmetic(left_encoded: u64, right_encoded: u64) i64 {
    if (!is_signed_i32_encoding(left_encoded) or !is_signed_i32_encoding(right_encoded)) return -1;
    const left_value = signed_sum_from_bits(@truncate(left_encoded));
    const right_value = signed_sum_from_bits(@truncate(right_encoded));
    var left: u32 = @truncate(left_encoded);
    var right: u32 = @truncate(right_encoded);
    while (right != 0) {
        const carry = left & right;
        left ^= right;
        right = carry << 1;
    }
    const result = signed_sum_from_bits(left);
    if ((left_value < 0) == (right_value < 0) and (result < 0) != (left_value < 0)) return -1;
    return result;
}
