module power_of_four;

// Positive powers of four within the signed 32-bit source domain.
fn long power_of_four(long value) @export("power_of_four") {
    if (value < -2147483648 || value > 2147483647) return -1;
    if (value <= 0 || (value & (value - 1)) != 0) return 0;
    return (value & 1431655765) != 0 ? 1 : 0;
}
