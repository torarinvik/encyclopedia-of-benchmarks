#include <stdint.h>

int64_t pell_number(int64_t index)
{
    if (index < 0 || index > 50) return -1;
    if (index == 0) return 0;
    int64_t previous = 0;
    int64_t current = 1;
    for (int64_t i = 2; i <= index; ++i) {
        int64_t next = 2 * current + previous;
        previous = current;
        current = next;
    }
    return current;
}
