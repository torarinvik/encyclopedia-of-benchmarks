/// Bit spreading for the pinned positive 32-bit source domain.
export fn next_power_of_two(number: i64) i64 {
    if (number < 1 or number > 1_073_741_824) return -1;
    if ((number & (number - 1)) == 0) return number;

    var value = number - 1;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return value + 1;
}
