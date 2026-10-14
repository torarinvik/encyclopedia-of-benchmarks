/// Positive powers of four within the signed 32-bit source domain.
export fn power_of_four(value: i64) i64 {
    if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
    if (value <= 0 or (value & (value - 1)) != 0) return 0;
    return if ((value & 0x5555_5555) != 0) 1 else 0;
}
