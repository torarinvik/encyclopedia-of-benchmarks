// Inclusive Fibonacci range sum for the shared unsigned pair ABI.
#include <cstdint>

static int64_t fibonacci_at(uint64_t index)
{
    if (index == 0) {
        return 0;
    }
    int64_t previous = 0;
    int64_t current = 1;
    for (uint64_t i = 1; i < index; ++i) {
        const int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}

extern "C" int64_t fibonacci_sum(uint64_t start, uint64_t end)
{
    if (end > 90 || start > end) {
        return -1;
    }
    return fibonacci_at(end + 2) - fibonacci_at(start + 1);
}
