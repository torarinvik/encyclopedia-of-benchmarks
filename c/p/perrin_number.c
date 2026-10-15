#include <stdint.h>

int64_t perrin_number(int64_t index)
{
    if (index < 0 || index > 155) return -1;
    if (index == 0) return 3;
    if (index == 1) return 0;
    if (index == 2) return 2;
    int64_t a = 3, b = 0, c = 2;
    int64_t result = 0;
    for (int64_t i = 3; i <= index; ++i) {
        result = a + b;
        a = b;
        b = c;
        c = result;
    }
    return result;
}
