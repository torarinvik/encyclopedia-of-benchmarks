#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 64;
constexpr std::int64_t min_cap = 3;
constexpr std::int64_t max_cap = 256;
constexpr std::size_t max_parseable_length = 3;

std::int64_t gcd_positive(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t construct_term(std::int64_t requested, std::int64_t candidate_cap) noexcept {
    std::int64_t terms[64]{1, 2, 3};
    bool used[257]{};
    if (requested <= 3) return terms[static_cast<std::size_t>(requested - 1)];
    used[1] = used[2] = used[3] = true;

    std::size_t term_count = 3;
    while (term_count < static_cast<std::size_t>(requested)) {
        const auto two_back = terms[term_count - 2];
        const auto previous = terms[term_count - 1];
        std::int64_t candidate = 1;
        while (candidate <= candidate_cap) {
            if (!used[static_cast<std::size_t>(candidate)]
                    && gcd_positive(candidate, two_back) > 1
                    && gcd_positive(candidate, previous) == 1) break;
            ++candidate;
        }
        if (candidate > candidate_cap) return -1;
        terms[term_count++] = candidate;
        used[static_cast<std::size_t>(candidate)] = true;
    }
    return terms[static_cast<std::size_t>(requested - 1)];
}
}

extern "C" std::int64_t yellowstone_permutation_prefix(
        const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 2) return -1;
    const auto requested = input[0];
    const auto candidate_cap = input[1];
    if (requested < 1 || requested > max_n
            || candidate_cap < min_cap || candidate_cap > max_cap) return -1;
    return construct_term(requested, candidate_cap);
}
