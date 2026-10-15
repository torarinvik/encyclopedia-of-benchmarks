module bitwise_addition;

// Add nonnegative integers with XOR and shifted AND carry propagation.
fn long bitwise_addition(ulong first, ulong second) @export("bitwise_addition") {
    while (second != 0) {
        ulong carry = first & second;
        first = first ^ second;
        second = carry << 1;
    }
    return (long)first;
}
