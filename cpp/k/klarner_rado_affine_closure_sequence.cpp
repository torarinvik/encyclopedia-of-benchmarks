#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_index = 64;
constexpr std::size_t max_parseable_length = 2;
}

extern "C" std::int64_t klarner_rado_affine_closure_sequence(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const auto requested = input[0];
    if (length != 1 || requested < 1 || requested > max_index) return -1;

    std::array<std::int64_t, 64> terms{};
    terms[0] = 1;
    std::size_t count = 1;
    std::size_t twice = 0, thrice_plus_two = 0, sixfold_plus_three = 0;
    while (count < static_cast<std::size_t>(requested)) {
        const auto by_two = 2 * terms[twice];
        const auto by_three = 3 * terms[thrice_plus_two] + 2;
        const auto by_six = 6 * terms[sixfold_plus_three] + 3;
        const auto next = std::min({by_two, by_three, by_six});
        terms[count++] = next;
        if (by_two == next) ++twice;
        if (by_three == next) ++thrice_plus_two;
        if (by_six == next) ++sixfold_plus_three;
    }
    return terms[static_cast<std::size_t>(requested) - 1];
}
