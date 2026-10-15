module next_power_of_two;

// Bit spreading for the pinned positive 32-bit source domain.
fn long next_power_of_two(long number) @export("next_power_of_two")
{
    if (number < 1 || number > 1073741824) return -1;
    ulong value = (ulong)number;
    if ((value & (value - 1)) == 0) return number;

    value--;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return (long)(value + 1);
}
