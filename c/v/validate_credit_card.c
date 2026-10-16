#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 64

int64_t validate_credit_card(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    int64_t n = input[0];
    if (n < 0 || n > MAX_TEXT_LENGTH || length != (size_t)n + 1) return -1;
    for (size_t i = 0; i < (size_t)n; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    if (n < 13 || n > 16) return 0;
    for (size_t i = 0; i < (size_t)n; ++i)
        if (input[i + 1] < '0' || input[i + 1] > '9') return 0;
    int64_t first = input[1] - '0';
    int64_t second = input[2] - '0';
    if (!(first == 4 || first == 5 || first == 6 ||
          (first == 3 && (second == 4 || second == 5 || second == 7)))) return 0;
    int sum = 0;
    for (size_t i = 0; i < (size_t)n; ++i) {
        int digit = (int)(input[i + 1] - '0');
        if (i % 2 == 0) { digit *= 2; if (digit > 9) digit -= 9; }
        sum += digit;
    }
    return sum % 10 == 0 ? 1 : 0;
}
