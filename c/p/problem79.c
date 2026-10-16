#include <stdint.h>

static const int LOGINS[50] = {
    319, 680, 180, 690, 129, 620, 762, 689, 762, 318,
    368, 710, 720, 710, 629, 168, 160, 689, 716, 731,
    736, 729, 316, 729, 729, 710, 769, 290, 719, 680,
    318, 389, 162, 289, 162, 718, 729, 319, 790, 680,
    890, 362, 319, 760, 316, 729, 380, 319, 728, 716
};

static int next_permutation(int64_t *digits, int length)
{
    int pivot = length - 2;
    while (pivot >= 0 && digits[pivot] >= digits[pivot + 1]) --pivot;
    if (pivot < 0) return 0;
    int successor = length - 1;
    while (digits[successor] <= digits[pivot]) --successor;
    int64_t temp = digits[pivot]; digits[pivot] = digits[successor]; digits[successor] = temp;
    for (int left = pivot + 1, right = length - 1; left < right; ++left, --right) {
        temp = digits[left]; digits[left] = digits[right]; digits[right] = temp;
    }
    return 1;
}

int64_t problem79(int64_t placeholder)
{
    if (placeholder != 0) return -1;
    uint8_t present[10] = {0};
    for (int i = 0; i < 50; ++i) {
        const int login = LOGINS[i];
        present[login / 100] = 1;
        present[(login / 10) % 10] = 1;
        present[login % 10] = 1;
    }
    int64_t digits[10];
    int length = 0;
    for (int digit = 0; digit <= 9; ++digit) if (present[digit]) digits[length++] = digit;
    do {
        int64_t position[10];
        for (int digit = 0; digit <= 9; ++digit) position[digit] = -1;
        for (int i = 0; i < length; ++i) position[digits[i]] = i;
        int satisfied = 1;
        for (int i = 0; i < 50; ++i) {
            const int login = LOGINS[i];
            const int first = login / 100, second = (login / 10) % 10, third = login % 10;
            if (!(position[first] < position[second] && position[second] < position[third])) { satisfied = 0; break; }
        }
        if (satisfied) {
            int64_t passcode = 0;
            for (int i = 0; i < length; ++i) passcode = passcode * 10 + digits[i];
            return passcode;
        }
    } while (next_permutation(digits, length));
    return -1;
}
