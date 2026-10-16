/* Count starts with the source's memoized digit-factorial chain length. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_START = 1'000'000;
constexpr std::size_t CACHE_SIZE = 2'540'161;
constexpr std::size_t MAX_PATH_LENGTH = 128;
constexpr std::int64_t DIGIT_FACTORIALS[10] = {
    1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880
};

std::int64_t sum_digit_factorials(std::int64_t value) noexcept
{
    std::int64_t total = 0;
    do {
        total += DIGIT_FACTORIALS[value % 10];
        value /= 10;
    } while (value > 0);
    return total;
}

int chain_length(std::int64_t start, std::uint8_t *cache) noexcept
{
    std::int64_t path[MAX_PATH_LENGTH]{};
    std::size_t path_length = 0;
    auto current = start;
    int result = 0;
    for (;;) {
        const auto encoded = cache[current];
        if (encoded != 0) {
            result = static_cast<int>(encoded) - 1;
            break;
        }
        const auto next = sum_digit_factorials(current);
        bool repeats = false;
        for (std::size_t index = 0; index < path_length; ++index) {
            if (path[index] == next) { repeats = true; break; }
        }
        if (repeats) {
            cache[current] = 1;
            result = 0;
            break;
        }
        path[path_length++] = current;
        current = next;
    }
    while (path_length > 0) {
        current = path[--path_length];
        ++result;
        cache[current] = static_cast<std::uint8_t>(result + 1);
    }
    return static_cast<int>(cache[start]) - 1;
}
}

extern "C" std::int64_t problem74(std::int64_t num_terms, std::int64_t max_start) noexcept
{
    if (max_start > MAX_START) return -1;
    if (max_start <= 1) return 0;
    std::uint8_t cache[CACHE_SIZE]{};
    cache[145] = 1;
    cache[169] = 4;
    cache[36301] = 4;
    cache[1454] = 4;
    cache[871] = 3;
    cache[45361] = 3;
    cache[872] = 3;
    std::int64_t count = 0;
    for (std::int64_t start = 1; start < max_start; ++start)
        if (chain_length(start, cache) == num_terms) ++count;
    return count;
}
