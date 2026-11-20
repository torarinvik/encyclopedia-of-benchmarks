// Pack a bounded prefix of OEIS A086747 using a zero-run parity automaton.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxCount = 63;

std::int64_t baum_sweet_term(std::int64_t number) noexcept {
    if (number == 0) return 0;
    std::int64_t mask = 1;
    while (mask <= number / 2) mask *= 2;
    bool odd_zero_run = false;
    while (mask > 0) {
        if ((number & mask) != 0) {
            if (odd_zero_run) return 0;
            odd_zero_run = false;
        } else {
            odd_zero_run = !odd_zero_run;
        }
        mask /= 2;
    }
    return odd_zero_run ? 0 : 1;
}
} // namespace

extern "C" std::int64_t baum_sweet_sequence(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 1) return -1;
    const std::int64_t count = input[0];
    if (count < 0 || count > kMaxCount) return -1;
    std::int64_t packed = 0;
    std::int64_t bit = 1;
    for (std::int64_t index = 0; index < count; ++index) {
        if (baum_sweet_term(index) != 0) packed += bit;
        if (index + 1 < count) bit *= 2;
    }
    return packed;
}
