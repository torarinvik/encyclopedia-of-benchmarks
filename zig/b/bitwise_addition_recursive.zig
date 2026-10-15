/// Add nonnegative integers by recursively propagating XOR carries.
fn addRecursive(first: i64, second: i64) i64 {
    const bitwise_sum = first ^ second;
    const carry = first & second;
    return if (carry == 0) bitwise_sum else addRecursive(bitwise_sum, carry << 1);
}

export fn bitwise_addition_recursive(first: i64, second: i64) i64 {
    if (first < 0 or first > 2_147_483_647 or second < 0 or second > 2_147_483_647) return -1;
    return addRecursive(first, second);
}
