#include <stdint.h>

int64_t make_change_sequence(int64_t amount) {
    if (amount < 0 || amount > 128) return -1;
    int64_t values[129] = {1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 11, 12, 15, 16, 19, 22, 25};
    for (int64_t n = 17; n <= amount; ++n) {
        values[n] = values[n - 2] + values[n - 5] - values[n - 7]
                  + values[n - 10] - values[n - 12] - values[n - 15]
                  + values[n - 17] + 1;
    }
    return values[amount];
}
