#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 14;
constexpr std::int64_t max_candidate = 64;
constexpr std::size_t max_sum = 74;
constexpr std::size_t max_parseable_length = 2;
}

extern "C" std::int64_t ulam_sequence_1_2(const std::int64_t* input,
                                            std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const auto requested = input[0];
    if (length != 1 || requested < 1 || requested > max_n) return -1;

    std::int64_t terms[14]{};
    std::int64_t representations[max_sum + 1]{};
    terms[0] = 1;
    terms[1] = 2;
    representations[3] = 1;
    std::size_t term_count = 2;

    while (term_count < static_cast<std::size_t>(requested)) {
        auto candidate = terms[term_count - 1] + 1;
        while (candidate <= max_candidate && representations[candidate] != 1) ++candidate;
        if (candidate > max_candidate) return -1;
        for (std::size_t old = 0; old < term_count; ++old) {
            const auto sum = static_cast<std::size_t>(candidate + terms[old]);
            if (representations[sum] < 2) ++representations[sum];
        }
        terms[term_count++] = candidate;
    }
    return terms[static_cast<std::size_t>(requested - 1)];
}
