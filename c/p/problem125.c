#include <stdint.h>
#include <stddef.h>

enum { MAX_LIMIT = 100000000, HASH_CAPACITY = 32768, HASH_MASK = HASH_CAPACITY - 1 };

static int is_palindrome(int64_t value)
{
    if (value % 10 == 0) return 0;
    int64_t original = value;
    int64_t reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return original == reversed;
}

static int insert_unique(int64_t *seen, int64_t value)
{
    size_t slot = (size_t)((((uint64_t)value * UINT64_C(2654435761)) >> 17) & HASH_MASK);
    while (seen[slot] != 0 && seen[slot] != value) slot = (slot + 1) & HASH_MASK;
    if (seen[slot] == value) return 0;
    seen[slot] = value;
    return 1;
}

int64_t problem125(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    int64_t seen[HASH_CAPACITY] = {0};
    int64_t total = 0;
    for (int64_t first = 1;; ++first) {
        int64_t last = first + 1;
        int64_t sum = first * first + last * last;
        if (sum >= limit) break;
        while (sum < limit) {
            if (is_palindrome(sum) && insert_unique(seen, sum)) total += sum;
            ++last;
            sum += last * last;
        }
    }
    return total;
}
