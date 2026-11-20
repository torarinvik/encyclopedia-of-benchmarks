#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 256, MAX_PATTERN = 16, ALPHABET = 16, SENTINEL = 16, MAX_INPUT = 274, SIDE = 17 };

int64_t berry_ravindran_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT) return -2;
    if (values[0] < 0 || values[0] > MAX_TEXT || values[1] < 1 || values[1] > MAX_PATTERN) return -2;
    const size_t n = (size_t)values[0], m = (size_t)values[1];
    if (length != 2 + n + m) return -2;
    for (size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] >= ALPHABET) return -2;
    if (m > n) return -1;
    const size_t pattern = 2 + n;
    size_t shift[SIDE * SIDE];
    for (size_t i = 0; i < SIDE * SIDE; ++i) shift[i] = m + 2;
    for (size_t a = 0; a < SIDE; ++a) shift[a * SIDE + (size_t)values[pattern]] = m + 1;
    for (size_t i = 0; i + 1 < m; ++i)
        shift[(size_t)values[pattern + i] * SIDE + (size_t)values[pattern + i + 1]] = m - i;
    for (size_t b = 0; b < SIDE; ++b)
        shift[(size_t)values[pattern + m - 1] * SIDE + b] = 1;
    size_t start = 0;
    while (start <= n - m) {
        size_t i = 0;
        while (i < m && values[2 + start + i] == values[pattern + i]) ++i;
        if (i == m) return (int64_t)start;
        const size_t first_index = start + m;
        if (first_index >= n) break;
        const size_t first = (size_t)values[2 + first_index];
        const size_t second = first_index + 1 < n ? (size_t)values[2 + first_index + 1] : SENTINEL;
        start += shift[first * SIDE + second];
    }
    return -1;
}
