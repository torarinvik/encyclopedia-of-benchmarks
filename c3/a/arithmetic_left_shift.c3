module arithmetic_left_shift;

const ulong MAX_U53 = 9007199254740991;
const long INVALID_RESULT = -1;

fn long arithmetic_left_shift(ulong n, ulong shift) @export("arithmetic_left_shift") {
    if (n > MAX_U53 || shift > 53) return INVALID_RESULT;
    return (long)((n << (usz)shift) & MAX_U53);
}
