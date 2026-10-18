module uint256_t;
const usz LIMBS = 8;

fn void divide_words(uint* dividend, uint* divisor, uint* quotient, uint* remainder) {
    uint[LIMBS + 1] rem = {};
    for (usz offset = 0; offset < LIMBS * 32; offset++) {
        usz bit = LIMBS * 32 - 1 - offset;
        uint carry = (dividend[bit / 32] >> (bit % 32)) & 1;
        for (usz i = 0; i < LIMBS; i++) { uint next = rem[i] >> 31; rem[i] = (rem[i] << 1) | carry; carry = next; }
        rem[LIMBS] = carry;
        int comparison = rem[LIMBS] == 0 ? 0 : 1;
        if (comparison == 0) {
            usz i = LIMBS;
            while (i > 0) { i--; if (rem[i] > divisor[i]) { comparison = 1; break; } if (rem[i] < divisor[i]) { comparison = -1; break; } }
        }
        if (comparison >= 0) {
            ulong borrow = 0;
            for (usz i = 0; i < LIMBS; i++) {
                ulong sub = (ulong)divisor[i] + borrow, old = rem[i];
                if (old >= sub) { rem[i] = (uint)(old - sub); borrow = 0; }
                else { rem[i] = (uint)(old + 0x100000000UL - sub); borrow = 1; }
            }
            rem[LIMBS] = (uint)((ulong)rem[LIMBS] - borrow);
            quotient[bit / 32] |= (uint)1 << (bit % 32);
        }
    }
    for (usz i = 0; i < LIMBS; i++) remainder[i] = rem[i];
}

fn long uint256_t(long* input, usz length, char* output, usz capacity) @export("uint256_t") {
    if (input == null || length < 1 || length > 18 || length != 1 + 2 * LIMBS) return -1;
    if (input[0] != 0 && input[0] != 1) return -1;
    uint[LIMBS] dividend = {}, divisor = {}, quotient = {}, remainder = {};
    bool nonzero = false;
    for (usz i = 0; i < LIMBS; i++) {
        long a = input[1 + i], b = input[1 + LIMBS + i];
        if (a < 0 || a > 4294967295L || b < 0 || b > 4294967295L) return -1;
        dividend[i] = (uint)a; divisor[i] = (uint)b; nonzero = nonzero || divisor[i] != 0;
    }
    if (!nonzero) return -1;
    if (output == null || capacity < 32) return -2;
    divide_words(&dividend[0], &divisor[0], &quotient[0], &remainder[0]);
    uint* answer = input[0] == 0 ? &quotient[0] : &remainder[0];
    for (usz i = 0; i < LIMBS; i++) for (usz byte = 0; byte < 4; byte++) output[i * 4 + byte] = (char)(answer[i] >> (byte * 8));
    return 32;
}
