/* Independent portable implementation of TheAlgorithms/C-Plus-Plus Fibonacci search. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t fibonacci_search(const std::int64_t *values,
                                          std::size_t length,
                                          std::int64_t target) noexcept
{
    if (length == 0) return -1;

    std::size_t fib_minus_two = 0;
    std::size_t fib_minus_one = 1;
    std::size_t fib = 1;
    while (fib < length) {
        fib_minus_two = fib_minus_one;
        fib_minus_one = fib;
        fib = fib_minus_two + fib_minus_one;
    }

    std::size_t offset_plus_one = 0;
    while (fib > 1) {
        std::size_t index = offset_plus_one + fib_minus_two - 1;
        if (index >= length) index = length - 1;
        const std::int64_t value = values[index];
        if (value == target) return static_cast<std::int64_t>(index);
        if (value < target) {
            fib = fib_minus_one;
            fib_minus_one = fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
            offset_plus_one = index + 1;
        } else {
            fib = fib_minus_two;
            fib_minus_one -= fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
        }
    }

    if (fib_minus_one != 0 && offset_plus_one < length && values[offset_plus_one] == target) {
        return static_cast<std::int64_t>(offset_plus_one);
    }
    return -1;
}
