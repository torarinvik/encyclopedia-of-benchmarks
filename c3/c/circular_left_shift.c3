module circular_left_shift;

fn long circular_left_shift(ulong value, ulong shift) @export("circular_left_shift")
{
    ulong mask = 9007199254740991;
    if (value > mask || shift > 53) return -1;
    uint amount = (uint)shift;
    ulong low = (value & (mask >> amount)) << amount;
    ulong high = value >> (53 - amount);
    return (long)(low | high);
}
