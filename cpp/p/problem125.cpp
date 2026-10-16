#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_LIMIT = 100000000;
constexpr std::size_t HASH_CAPACITY = 32768;
constexpr std::size_t HASH_MASK = HASH_CAPACITY - 1;

bool is_palindrome(std::int64_t value) noexcept
{
    if (value % 10 == 0) return false;
    const std::int64_t original = value;
    std::int64_t reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return original == reversed;
}

bool insert_unique(std::int64_t* seen, std::int64_t value) noexcept
{
    std::size_t slot = static_cast<std::size_t>(((static_cast<std::uint64_t>(value) * UINT64_C(2654435761)) >> 17) & HASH_MASK);
    while (seen[slot] != 0 && seen[slot] != value) slot = (slot + 1) & HASH_MASK;
    if (seen[slot] == value) return false;
    seen[slot] = value;
    return true;
}
}

extern "C" std::int64_t problem125(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    std::int64_t seen[HASH_CAPACITY] = {};
    std::int64_t total = 0;
    for (std::int64_t first = 1;; ++first) {
        std::int64_t last = first + 1;
        std::int64_t sum = first * first + last * last;
        if (sum >= limit) break;
        while (sum < limit) {
            if (is_palindrome(sum) && insert_unique(seen, sum)) total += sum;
            ++last;
            sum += last * last;
        }
    }
    return total;
}
