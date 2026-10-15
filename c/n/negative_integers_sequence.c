#include <stdint.h>

int64_t negative_integers_sequence(int64_t index)
{
    if (index < 0) return 0;
    return -index - 1;
}
