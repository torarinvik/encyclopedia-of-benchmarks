/* Return a term from the bounded powers-of-two sequence. */
#include <stdint.h>

int64_t powers_of2_sequence(int64_t index)
{
    if (index < 0 || index > 62) return -1;
    int64_t value = 1;
    for (int64_t step = 0; step < index; ++step) value *= 2;
    return value;
}
