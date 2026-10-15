/// Return the isolated least significant set bit.
export fn lowest_set_bit(value: i64) i64 {
    if (value < 0 or value > 2_147_483_647) return -1;
    return value & -value;
}
