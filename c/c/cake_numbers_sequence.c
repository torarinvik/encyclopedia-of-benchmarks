#include <stdint.h>

int64_t cake_numbers_sequence(int64_t n) {
    if (n < 0 || n > 2000000) return -1;
    return (n * n * n + 5 * n + 6) / 6;
}
