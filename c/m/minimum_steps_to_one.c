/* Forward-tabulated minimum steps from 1 using +1, *2, or *3. */
#include <stdint.h>

#define MAX_N 10000

int64_t minimum_steps_to_one(int64_t n)
{
    if (n < 1 || n > MAX_N) return -1;
    int64_t table[MAX_N + 1];
    for (int64_t index = 0; index <= n; ++index) table[index] = n + 1;
    table[1] = 0;
    for (int64_t i = 1; i < n; ++i) {
        if (table[i + 1] > table[i] + 1) table[i + 1] = table[i] + 1;
        if (i * 2 <= n && table[i * 2] > table[i] + 1) table[i * 2] = table[i] + 1;
        if (i * 3 <= n && table[i * 3] > table[i] + 1) table[i * 3] = table[i] + 1;
    }
    return table[n];
}
