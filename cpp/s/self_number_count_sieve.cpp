#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 100000;
constexpr std::size_t max_parseable_length = 2;
constexpr std::size_t word_count = 1563;

std::int64_t digit_sum10(std::int64_t value) noexcept {
    std::int64_t sum = 0;
    while (value > 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}
}

extern "C" std::int64_t self_number_count_sieve(const std::int64_t* input,
                                                 std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const auto limit = input[0];
    if (length != 1 || limit < 1 || limit > max_limit) return -1;

    std::uint64_t generated[word_count]{};
    for (std::int64_t source = 1; source <= limit; ++source) {
        const auto target = source + digit_sum10(source);
        if (target <= limit) generated[static_cast<std::size_t>(target >> 6)] |=
            UINT64_C(1) << static_cast<unsigned>(target & 63);
    }
    std::int64_t count = 0;
    for (std::int64_t value = 1; value <= limit; ++value) {
        if ((generated[static_cast<std::size_t>(value >> 6)] &
             (UINT64_C(1) << static_cast<unsigned>(value & 63))) == 0) ++count;
    }
    return count;
}
