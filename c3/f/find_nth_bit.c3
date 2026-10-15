module find_nth_bit;

const ulong MAX_NUM = 2147483647;
const long INVALID_RESULT = -1;

fn long find_nth_bit(ulong num, ulong n) @export("find_nth_bit") {
    if (num > MAX_NUM || n < 1 || n > 31) return INVALID_RESULT;
    int value = (int)num;
    int shift = (int)(n - 1);
    return (long)((value & (1 << shift)) >> shift);
}
