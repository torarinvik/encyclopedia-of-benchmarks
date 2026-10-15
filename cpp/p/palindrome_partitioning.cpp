/* Return the minimum cuts needed to split ASCII bytes into palindromes. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 256;
}

extern "C" std::int64_t palindrome_partitioning(const std::int64_t *input,
                                                  std::size_t length,
                                                  std::uint8_t *output,
                                                  std::size_t output_capacity) noexcept
{
    if (input == nullptr || length == 0 || length > MAX_LENGTH) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (output == nullptr || output_capacity < 8) return -2;

    bool palindrome[MAX_LENGTH][MAX_LENGTH]{};
    std::int64_t cuts[MAX_LENGTH]{};
    for (std::size_t end = 0; end < length; ++end) {
        std::int64_t best = static_cast<std::int64_t>(end);
        for (std::size_t start = 0; start <= end; ++start) {
            if (input[start] == input[end] &&
                (end - start < 2 || palindrome[start + 1][end - 1])) {
                palindrome[start][end] = true;
                const std::int64_t candidate = start == 0 ? 0 : cuts[start - 1] + 1;
                if (candidate < best) best = candidate;
            }
        }
        cuts[end] = best;
    }

    const auto bits = static_cast<std::uint64_t>(cuts[length - 1]);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    return 1;
}
