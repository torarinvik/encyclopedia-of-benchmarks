#include <stdint.h>

#define MAX_INPUT INT64_C(1000000)

/* Preserve the pinned Java rank loop, including counter += 1 each round. */
int64_t lucky_number(int64_t number)
{
    if (number < 1 || number > MAX_INPUT) return -1;
    int64_t counter = 2;
    int64_t position = number;
    while (counter <= position) {
        if (position % counter == 0) return 0;
        position -= position / counter;
        ++counter;
    }
    return 1;
}
