#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 30;
constexpr std::size_t max_parseable_length = 2;
constexpr std::size_t max_sums = 465;
}

extern "C" std::int64_t mian_chowla_sequence(const std::int64_t* input,
                                               std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const auto requested = input[0];
    if (length != 1 || requested < 1 || requested > max_n) return -1;

    std::int64_t terms[30]{};
    std::int64_t used_sums[max_sums]{};
    std::size_t term_count = 1;
    std::size_t sum_count = 1;
    terms[0] = 1;
    used_sums[0] = 2;

    while (term_count < static_cast<std::size_t>(requested)) {
        auto candidate = terms[term_count - 1] + 1;
        for (;;) {
            bool valid = true;
            for (std::size_t term = 0; term < term_count && valid; ++term) {
                const auto sum = candidate + terms[term];
                for (std::size_t old = 0; old < sum_count; ++old) {
                    if (used_sums[old] == sum) { valid = false; break; }
                }
            }
            if (valid) {
                const auto doubled = 2 * candidate;
                for (std::size_t old = 0; old < sum_count; ++old) {
                    if (used_sums[old] == doubled) { valid = false; break; }
                }
            }
            if (valid) break;
            ++candidate;
        }

        for (std::size_t term = 0; term < term_count; ++term)
            used_sums[sum_count++] = candidate + terms[term];
        used_sums[sum_count++] = 2 * candidate;
        terms[term_count++] = candidate;
    }
    return terms[static_cast<std::size_t>(requested) - 1];
}
