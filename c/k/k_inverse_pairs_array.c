#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 128, MAX_K = 512 };
static const int64_t MODULUS = INT64_C(1000000007);

int64_t k_inverse_pairs_array(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 3 || length != 2) return -1;
    const int64_t n_value = input[0], k_value = input[1];
    if (n_value < 0 || n_value > MAX_N || k_value < 0 || k_value > MAX_K) return -1;
    const size_t n = (size_t)n_value, k = (size_t)k_value;
    if (k > n * (n - (n > 0 ? 1 : 0)) / 2) return 0;

    int64_t first_row[MAX_K + 1] = {0}, second_row[MAX_K + 1] = {0};
    int64_t *previous = first_row, *current = second_row;
    previous[0] = 1;
    for (size_t size = 1; size <= n; ++size) {
        int64_t window = 0;
        for (size_t inversions = 0; inversions <= k; ++inversions) {
            window += previous[inversions];
            if (inversions >= size) window -= previous[inversions - size];
            window %= MODULUS;
            if (window < 0) window += MODULUS;
            current[inversions] = window;
        }
        int64_t *temporary = previous;
        previous = current;
        current = temporary;
    }
    return previous[k];
}
