#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int64_t max_limit = 100000;
constexpr std::size_t max_queue = 70000;

bool is_prime(int64_t value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor * divisor <= value; divisor += 2)
        if (value % divisor == 0) return false;
    return true;
}
}

extern "C" int64_t left_truncatable_prime_search(const int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > 3) return -1;
    const int64_t base = input[0], digits = input[1];
    if (length != 2 || base < 3 || base > 16 || digits < 1 || digits > 10) return -1;
    int64_t limit = 1;
    for (int64_t i = 0; i < digits; ++i) limit *= base;
    if (limit > max_limit) return -1;

    std::array<int64_t, max_queue> queue{};
    std::size_t end = 0;
    for (int64_t value = 2; value < base; ++value)
        if (is_prime(value)) queue[end++] = value;
    int64_t best = queue[end - 1];
    std::size_t level_start = 0, level_end = end;
    int64_t place = base;
    for (int64_t width = 1; width < digits && level_start < level_end; ++width) {
        for (std::size_t index = level_start; index < level_end; ++index) {
            const int64_t suffix = queue[index];
            for (int64_t leading = 1; leading < base; ++leading) {
                const int64_t candidate = leading * place + suffix;
                if (is_prime(candidate)) {
                    if (end >= max_queue) return -1;
                    queue[end++] = candidate;
                    if (candidate > best) best = candidate;
                }
            }
        }
        level_start = level_end;
        level_end = end;
        place *= base;
    }
    return best;
}
