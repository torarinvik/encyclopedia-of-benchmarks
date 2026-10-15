/* Count denomination combinations with the source's recursive recurrence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_AMOUNT 30
#define MAX_DENOMINATIONS 4

static int64_t ways(int64_t amount, const int64_t *input, int64_t count)
{
    if (amount < 0 || count < 0) return 0;
    if (amount == 0) return 1;
    if (count == 0) return 0;
    const int64_t denomination = input[count + 1];
    return ways(amount, input, count - 1)
        + ways(amount - denomination, input, count);
}

int64_t demonetization(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_DENOMINATIONS + 2) return -1;
    const int64_t amount = input[0];
    const int64_t count = input[1];
    if (amount < -MAX_AMOUNT || amount > MAX_AMOUNT || count < 0 || count > MAX_DENOMINATIONS
        || length != (size_t)(count + 2)) return -1;
    for (int64_t index = 0; index < count; ++index)
        if (input[index + 2] < 1 || input[index + 2] > MAX_AMOUNT) return -1;
    return ways(amount, input, count);
}
