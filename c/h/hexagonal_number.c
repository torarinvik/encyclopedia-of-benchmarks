/* Return the nth hexagonal number for a JS-safe positive index. */
#include <stdint.h>

int64_t hexagonal_number(int64_t number)
{
    if (number < 1 || number > 67108864) return -1;
    return number * (2 * number - 1);
}
