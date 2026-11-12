#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxSourceLength = 6;
constexpr std::size_t kMaxInputLength = 16;
constexpr std::size_t kMaxOutputLength = 12;

struct Sequence {
    std::array<std::uint8_t, kMaxOutputLength> values{};
    std::size_t length = 0;
};

Sequence maximum_subsequence(const std::int64_t *source, std::size_t length,
                              std::size_t requested)
{
    std::array<std::uint8_t, kMaxSourceLength> stack{};
    std::size_t stack_length = 0;
    std::size_t deletions = length - requested;
    for (std::size_t i = 0; i < length; ++i) {
        const auto digit = static_cast<std::uint8_t>(source[i]);
        while (deletions > 0 && stack_length > 0 && stack[stack_length - 1] < digit) {
            --stack_length;
            --deletions;
        }
        stack[stack_length++] = digit;
    }
    stack_length -= deletions;
    Sequence selected;
    selected.length = stack_length;
    for (std::size_t i = 0; i < stack_length; ++i) selected.values[i] = stack[i];
    return selected;
}

int compare_suffix(const Sequence &first, std::size_t first_at,
                   const Sequence &second, std::size_t second_at) noexcept
{
    while (first_at < first.length && second_at < second.length) {
        if (first.values[first_at] != second.values[second_at])
            return first.values[first_at] > second.values[second_at] ? 1 : -1;
        ++first_at;
        ++second_at;
    }
    if (first_at == first.length && second_at == second.length) return 0;
    return first_at == first.length ? -1 : 1;
}

Sequence merge_sequences(const Sequence &first, const Sequence &second) noexcept
{
    Sequence merged;
    std::size_t i = 0;
    std::size_t j = 0;
    while (i < first.length || j < second.length) {
        const int order = compare_suffix(first, i, second, j);
        if (j == second.length || (i < first.length && order >= 0))
            merged.values[merged.length++] = first.values[i++];
        else
            merged.values[merged.length++] = second.values[j++];
    }
    return merged;
}

bool greater(const Sequence &left, const Sequence &right) noexcept
{
    for (std::size_t i = 0; i < left.length; ++i) {
        if (left.values[i] != right.values[i]) return left.values[i] > right.values[i];
    }
    return false;
}
}

extern "C" std::int64_t create_maximum_number(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxInputLength) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxSourceLength)
        || input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxSourceLength)) return -1;
    const auto first_length = static_cast<std::size_t>(input[0]);
    const auto second_length = static_cast<std::size_t>(input[1]);
    if (input[2] < 0 || input[2] > static_cast<std::int64_t>(first_length + second_length)) return -1;
    const auto requested = static_cast<std::size_t>(input[2]);
    if (length != 3 + first_length + second_length) return -1;
    for (std::size_t i = 0; i < first_length + second_length; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 9) return -1;
    if (output == nullptr || capacity < requested) return -2;

    const auto *first_source = input + 3;
    const auto *second_source = first_source + first_length;
    const auto minimum_first = requested > second_length ? requested - second_length : 0;
    const auto maximum_first = requested < first_length ? requested : first_length;
    Sequence best;
    bool have_best = false;
    for (std::size_t take_first = minimum_first; take_first <= maximum_first; ++take_first) {
        const auto first = maximum_subsequence(first_source, first_length, take_first);
        const auto second = maximum_subsequence(second_source, second_length, requested - take_first);
        const auto candidate = merge_sequences(first, second);
        if (!have_best || greater(candidate, best)) {
            best = candidate;
            have_best = true;
        }
    }
    for (std::size_t i = 0; i < requested; ++i) output[i] = best.values[i];
    return static_cast<std::int64_t>(requested);
}
