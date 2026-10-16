/* Return the final term of a bounded N-bonacci sequence. */
#include <stddef.h>
#include <stdint.h>

int64_t n_bonacci(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    int64_t order_value = values[0];
    int64_t count_value = values[1];
    if (order_value < 1 || count_value <= order_value || count_value > 64) return -1;
    size_t order = (size_t)order_value;
    size_t count = (size_t)count_value;
    int64_t terms[64] = {0};
    terms[order - 1] = 1;
    terms[order] = 1;
    for (size_t i = order + 1; i < count; ++i) {
        terms[i] = 2 * terms[i - 1] - terms[i - 1 - order];
    }
    return terms[count - 1];
}
