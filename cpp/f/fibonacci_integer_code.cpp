#include <cstddef>
#include <cstdint>

extern "C" std::int64_t fibonacci_integer_code(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > 33) return -1;
    const auto n0 = input[0];
    if (n0 < 1 || n0 > 32 || length != static_cast<std::size_t>(n0) + 1) return -1;
    const auto n = static_cast<std::size_t>(n0);
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 1000000) return -1;
    std::uint64_t fib[30]{}; std::size_t fib_count = 2; fib[0] = 1; fib[1] = 2;
    while (fib_count < 30 && fib[fib_count - 1] + fib[fib_count - 2] <= 1000001) {
        fib[fib_count] = fib[fib_count - 1] + fib[fib_count - 2]; ++fib_count;
    }
    std::uint8_t staged[960]{}; std::size_t out = 0;
    for (std::size_t v = 0; v < n; ++v) {
        auto remaining = static_cast<std::uint64_t>(input[v + 1]) + 1;
        std::size_t top = 0;
        while (top + 1 < fib_count && fib[top + 1] <= remaining) ++top;
        std::uint8_t bits[30]{};
        for (std::size_t j = top + 1; j > 0; --j) {
            const auto i = j - 1;
            if (fib[i] <= remaining) { bits[i] = 1; remaining -= fib[i]; }
        }
        for (std::size_t i = 0; i <= top; ++i) staged[out++] = static_cast<std::uint8_t>('0' + bits[i]);
        staged[out++] = '1';
    }
    if (!output || capacity < out) return -2;
    for (std::size_t i = 0; i < out; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(out);
}
