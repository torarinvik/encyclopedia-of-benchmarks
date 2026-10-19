#include <stdint.h>

#define MAX_N 15

int64_t nestedloop(int64_t input) {
    if (input < 0 || input > MAX_N) return -1;
    const int n = (int)input;
    int a, b, c, d, e, f, x = 0;
    for (a = 0; a < n; a++)
        for (b = 0; b < n; b++)
            for (c = 0; c < n; c++)
                for (d = 0; d < n; d++)
                    for (e = 0; e < n; e++)
                        for (f = 0; f < n; f++)
                            x++;
    return x;
}
