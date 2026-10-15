// Stack of unmatched opening positions for longest valid parentheses.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t longest_valid_parentheses_stack(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] != 40 && input[index] != 41) return -1;

    std::int64_t unmatched[max_length + 1];
    std::size_t top = 0;
    unmatched[top] = -1;
    std::size_t best = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] == 40) {
            unmatched[++top] = static_cast<std::int64_t>(index);
        } else if (top == 0) {
            unmatched[0] = static_cast<std::int64_t>(index);
        } else {
            --top;
            const auto start = unmatched[top];
            const auto current = static_cast<std::size_t>(static_cast<std::int64_t>(index) - start);
            if (current > best) best = current;
        }
    }
    return static_cast<std::int64_t>(best);
}
