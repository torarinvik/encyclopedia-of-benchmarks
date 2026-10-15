module arithmetic_right_shift;

const ulong MAX_U53 = 9007199254740991;
const long INVALID_RESULT = -1;

fn long arithmetic_right_shift(ulong n, ulong shift) @export("arithmetic_right_shift") {
    if (n > MAX_U53 || shift > 53) return INVALID_RESULT;
    usz count = (usz)shift;
    ulong low_mask = ((ulong)1 << (usz)(53 - count)) - 1;
    ulong fill_mask = (n >> 52) != 0 ? (MAX_U53 ^ low_mask) : 0;
    return (long)(fill_mask | (n >> count));
}
