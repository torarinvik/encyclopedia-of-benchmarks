/// Add nonnegative integers with XOR and shifted AND carry propagation.
export fn bitwise_addition(first_value: u64, second_value: u64) i64 {
    var first = first_value;
    var second = second_value;
    while (second != 0) {
        const carry = first & second;
        first ^= second;
        second = carry << 1;
    }
    return @intCast(first);
}
