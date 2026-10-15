#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define MAX_DIMENSION INT64_C(1000)

int64_t volume(const int64_t *input, size_t length)
{
    if (input == NULL || length != 4) return INVALID_RESULT;
    const int64_t operation = input[0];
    const int64_t a = input[1], b = input[2], c = input[3];
    if (a < 0 || a > MAX_DIMENSION || b < 0 || b > MAX_DIMENSION || c < 0 || c > MAX_DIMENSION) return INVALID_RESULT;
    if (operation == 0) {
        if (b != 0 || c != 0) return INVALID_RESULT;
        return a * a * a;
    }
    if (operation == 1) return a * b * c;
    if (operation == 2) {
        const int64_t product = a * b * c;
        return product % 2 == 0 ? product / 2 : INVALID_RESULT;
    }
    if (operation == 3) {
        const int64_t product = a * b * c;
        return product % 3 == 0 ? product / 3 : INVALID_RESULT;
    }
    return INVALID_RESULT;
}
