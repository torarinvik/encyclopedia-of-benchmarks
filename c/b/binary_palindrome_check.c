/* Test whether the significant binary digits of an int32 value form a palindrome. */
#include <stdint.h>
#include <limits.h>

int64_t binary_palindrome_check(int64_t number)
{
    if (number < INT32_MIN || number > INT32_MAX) return -1;
    if (number < 0) return 0;
    int64_t remaining = number;
    int64_t reversed = 0;
    while (remaining > 0) {
        reversed = (reversed << 1) | (remaining & 1);
        remaining >>= 1;
    }
    return reversed == number ? 1 : 0;
}
