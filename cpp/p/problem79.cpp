#include <cstdint>

static constexpr int LOGINS[50] = {
    319, 680, 180, 690, 129, 620, 762, 689, 762, 318,
    368, 710, 720, 710, 629, 168, 160, 689, 716, 731,
    736, 729, 316, 729, 729, 710, 769, 290, 719, 680,
    318, 389, 162, 289, 162, 718, 729, 319, 790, 680,
    890, 362, 319, 760, 316, 729, 380, 319, 728, 716
};

static bool next_permutation(std::int64_t *digits, int length) noexcept
{
    int pivot = length - 2;
    while (pivot >= 0 && digits[pivot] >= digits[pivot + 1]) --pivot;
    if (pivot < 0) return false;
    int successor = length - 1;
    while (digits[successor] <= digits[pivot]) --successor;
    const auto temp = digits[pivot]; digits[pivot] = digits[successor]; digits[successor] = temp;
    for (int left = pivot + 1, right = length - 1; left < right; ++left, --right) {
        const auto value = digits[left]; digits[left] = digits[right]; digits[right] = value;
    }
    return true;
}

extern "C" std::int64_t problem79(std::int64_t placeholder) noexcept
{
    if (placeholder != 0) return -1;
    bool present[10]{};
    for (const int login : LOGINS) {
        present[login / 100] = true;
        present[(login / 10) % 10] = true;
        present[login % 10] = true;
    }
    std::int64_t digits[10];
    int length = 0;
    for (int digit = 0; digit <= 9; ++digit) if (present[digit]) digits[length++] = digit;
    do {
        int position[10];
        for (int digit = 0; digit <= 9; ++digit) position[digit] = -1;
        for (int i = 0; i < length; ++i) position[digits[i]] = i;
        bool satisfied = true;
        for (const int login : LOGINS) {
            const int first = login / 100, second = (login / 10) % 10, third = login % 10;
            if (!(position[first] < position[second] && position[second] < position[third])) { satisfied = false; break; }
        }
        if (satisfied) {
            std::int64_t passcode = 0;
            for (int i = 0; i < length; ++i) passcode = passcode * 10 + digits[i];
            return passcode;
        }
    } while (next_permutation(digits, length));
    return -1;
}
