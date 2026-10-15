#include <stddef.h>
#include <stdint.h>

#define MAX_NUMBER INT64_C(1000000)

static int is_prime(int64_t value)
{
    if (value == 2) return 1;
    if (value < 2 || value % 2 == 0) return 0;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t germain_prime_and_safe_prime(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    const int64_t number = values[0];
    const int64_t selector = values[1];
    if (number < 1 || number > MAX_NUMBER || selector < 0 || selector > 1) return -1;
    if (selector == 0) return is_prime(number) && is_prime(2 * number + 1);
    return ((number - 1) % 2 == 0 && is_prime(number) && is_prime((number - 1) / 2)) ? 1 : 0;
}
