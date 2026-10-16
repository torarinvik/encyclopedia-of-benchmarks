/* Direct permutation port of TheAlgorithms/Python Project Euler 43. */
#include <stdint.h>

static int next_permutation(int digits[10]) {
    int i = 8;
    while (i >= 0 && digits[i] >= digits[i + 1]) --i;
    if (i < 0) return 0;
    int j = 9;
    while (digits[j] <= digits[i]) --j;
    int temp = digits[i]; digits[i] = digits[j]; digits[j] = temp;
    for (int left = i + 1, right = 9; left < right; ++left, --right) {
        temp = digits[left]; digits[left] = digits[right]; digits[right] = temp;
    }
    return 1;
}

int64_t problem43(int64_t n) {
    if (n != 10) return -1;
    int digits[10]; for (int i = 0; i < 10; ++i) digits[i] = i;
    int64_t total = 0;
    do {
        if (digits[3] % 2 || (digits[2] + digits[3] + digits[4]) % 3 || digits[5] % 5) continue;
        int divisors[4] = {7, 11, 13, 17}, valid = 1;
        for (int i = 0; i < 4; ++i)
            if ((digits[i+4]*100 + digits[i+5]*10 + digits[i+6]) % divisors[i]) valid = 0;
        if (valid) { int64_t value = 0; for (int i = 0; i < 10; ++i) value = value*10 + digits[i]; total += value; }
    } while (next_permutation(digits));
    return total;
}
