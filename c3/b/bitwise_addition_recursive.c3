module bitwise_addition_recursive;

fn long add_recursive(long first, long second) {
    long bitwise_sum = first ^ second;
    long carry = first & second;
    return carry == 0 ? bitwise_sum : add_recursive(bitwise_sum, carry << 1);
}

fn long bitwise_addition_recursive(long first, long second) @export("bitwise_addition_recursive") {
    if (first < 0 || first > 2147483647 || second < 0 || second > 2147483647) return -1;
    return add_recursive(first, second);
}
