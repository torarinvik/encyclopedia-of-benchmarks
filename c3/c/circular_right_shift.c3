module circular_right_shift;

fn long circular_right_shift(ulong value, ulong shift) @export("circular_right_shift")
{
    ulong mask = 9007199254740991;
    if (value > mask || shift > 53) return -1;
    uint amount = (uint)shift;
    ulong low_mask = mask >> (53 - amount);
    ulong low = (value & low_mask) << (53 - amount);
    ulong high = value >> amount;
    return (long)(low | high);
}
