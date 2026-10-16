/* Validate an ASCII credit card string using prefix, length, and Luhn checks. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 64

int64_t credit_card_validator(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    int64_t n = input[0];
    if (n < 0 || n > MAX_TEXT_LENGTH || length != (size_t)n + 1) return -1;
    int digits = 1;
    for (size_t i = 0; i < (size_t)n; ++i) {
        int64_t ch = input[i + 1];
        if (ch < 0 || ch > 127) return -1;
        if (ch < '0' || ch > '9') digits = 0;
    }
    if (!digits || n < 13 || n > 16) return 0;
    int64_t first = input[1] - '0';
    int64_t second = n >= 2 ? input[2] - '0' : -1;
    int prefix = first == 4 || first == 5 || first == 6 ||
        (first == 3 && (second == 4 || second == 5 || second == 7));
    if (!prefix) return 0;
    int sum = 0;
    for (size_t i = 0; i < (size_t)n; ++i) {
        int digit = (int)(input[i + 1] - '0');
        if ((int64_t)(i % 2) == n % 2) { digit *= 2; if (digit > 9) digit -= 9; }
        sum += digit;
    }
    return sum % 10 == 0 ? 1 : 0;
}
