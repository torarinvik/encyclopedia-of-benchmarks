module problem80;

const usz LIMBS = 16;
const ulong BASE = 1000000000;

fn void mul_add(ulong* src, ulong factor, ulong add, ulong* dst) {
    ulong carry = add;
    for (usz i = 0; i < LIMBS; i++) {
        ulong value = src[i] * factor + carry;
        dst[i] = value % BASE;
        carry = value / BASE;
    }
}
fn bool ge(ulong* left, ulong* right) {
    for (isz i = (isz)LIMBS - 1; i >= 0; i--) {
        if (left[i] != right[i]) return left[i] > right[i];
    }
    return true;
}
fn void subtract(ulong* left, ulong* right) {
    ulong borrow = 0;
    for (usz i = 0; i < LIMBS; i++) {
        ulong amount = right[i] + borrow;
        if (left[i] < amount) { left[i] = left[i] + BASE - amount; borrow = 1; }
        else { left[i] -= amount; borrow = 0; }
    }
}

fn long problem80(long placeholder) @export("problem80") {
    if (placeholder != 0) return -1;
    long answer = 0;
    for (ulong number = 2; number < 100; number++) {
        ulong integer_root = 0;
        while ((integer_root + 1) * (integer_root + 1) <= number) integer_root++;
        if (integer_root * integer_root == number) continue;
        ulong[LIMBS] root = {0}, remainder = {0}, scaled = {0}, trial = {0};
        long digit_sum = 0;
        for (usz step = 0; step < 100; step++) {
            mul_add(&remainder[0], 100, step == 0 ? number : 0, &remainder[0]);
            long digit = 9;
            while (digit >= 0) {
                mul_add(&root[0], 20, (ulong)digit, &scaled[0]);
                mul_add(&scaled[0], (ulong)digit, 0, &trial[0]);
                if (ge(&remainder[0], &trial[0])) break;
                digit--;
            }
            subtract(&remainder[0], &trial[0]);
            mul_add(&root[0], 10, (ulong)digit, &root[0]);
            digit_sum += digit;
        }
        answer += digit_sum;
    }
    return answer;
}
