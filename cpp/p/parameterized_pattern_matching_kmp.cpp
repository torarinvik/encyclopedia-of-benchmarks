#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxText = 64;
constexpr std::size_t kMaxPattern = 16;
constexpr std::size_t kMaxAlphabet = 16;
constexpr std::size_t kMaxParseableInput = 84;
constexpr std::size_t kMaxOutputBytes = 520;

void store_word(std::array<std::uint8_t, kMaxOutputBytes> &bytes,
                std::size_t word, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        bytes[word * 8 + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

bool pattern_pair_matches(const std::array<std::int64_t, kMaxPattern> &pattern,
                          const std::array<int, kMaxPattern> &previous,
                          const std::array<int, kMaxPattern> &previous_at,
                          std::size_t current, std::size_t prefix_position)
{
    const int prior = previous[current];
    if (prior < 0 || static_cast<int>(current) - prior > static_cast<int>(prefix_position)) {
        return previous_at[prefix_position] < 0;
    }
    const auto distance = current - static_cast<std::size_t>(prior);
    return pattern[prefix_position] == pattern[prefix_position - distance];
}

bool text_symbol_matches(const std::int64_t *text, std::size_t text_position,
                         std::size_t pattern_position,
                         const std::array<int, kMaxPattern> &previous,
                         const std::array<int, kMaxAlphabet> &last_text)
{
    const int prior = previous[pattern_position];
    const auto symbol = static_cast<std::size_t>(text[text_position]);
    if (prior < 0) {
        return last_text[symbol] < static_cast<int>(text_position - pattern_position);
    }
    const auto distance = pattern_position - static_cast<std::size_t>(prior);
    return text[text_position] == text[text_position - distance];
}
} // namespace

extern "C" std::int64_t parameterized_pattern_matching_kmp(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxParseableInput) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    const auto alphabet_value = input[2];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(kMaxText) ||
        m_value < 1 || m_value > static_cast<std::int64_t>(kMaxPattern) ||
        alphabet_value < 1 || alphabet_value > static_cast<std::int64_t>(kMaxAlphabet)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    const auto alphabet_size = static_cast<std::uint64_t>(alphabet_value);
    if (length != 3 + n + m) return -1;
    for (std::size_t index = 3; index < length; ++index) {
        if (input[index] < 0 || static_cast<std::uint64_t>(input[index]) >= alphabet_size) return -1;
    }

    const auto *text = input + 3;
    const auto *pattern_input = text + n;
    std::array<std::int64_t, kMaxPattern> pattern{};
    std::array<int, kMaxPattern> previous{};
    std::array<int, kMaxPattern> previous_at{};
    std::array<int, kMaxAlphabet> last_pattern{};
    std::array<int, kMaxPattern> failure{};
    last_pattern.fill(-1);
    for (std::size_t index = 0; index < m; ++index) {
        pattern[index] = pattern_input[index];
        const auto symbol = static_cast<std::size_t>(pattern[index]);
        previous[index] = last_pattern[symbol];
        previous_at[index] = previous[index];
        last_pattern[symbol] = static_cast<int>(index);
    }

    for (std::size_t current = 1; current < m; ++current) {
        std::size_t matched = static_cast<std::size_t>(failure[current - 1]);
        while (matched > 0 && !pattern_pair_matches(pattern, previous, previous_at,
                                                    current, matched)) {
            matched = static_cast<std::size_t>(failure[matched - 1]);
        }
        if (pattern_pair_matches(pattern, previous, previous_at, current, matched)) ++matched;
        failure[current] = static_cast<int>(matched);
    }

    std::array<int, kMaxAlphabet> last_text{};
    last_text.fill(-1);
    std::array<std::int64_t, kMaxText> matches{};
    std::size_t match_count = 0;
    std::size_t matched = 0;
    if (m <= n) {
        for (std::size_t text_position = 0; text_position < n; ++text_position) {
            for (;;) {
                if (text_symbol_matches(text, text_position, matched, previous, last_text)) {
                    ++matched;
                    if (matched == m) {
                        matches[match_count++] = static_cast<std::int64_t>(text_position + 1 - m);
                        matched = static_cast<std::size_t>(failure[m - 1]);
                    }
                    break;
                }
                if (matched == 0) break;
                matched = static_cast<std::size_t>(failure[matched - 1]);
            }
            last_text[static_cast<std::size_t>(text[text_position])] = static_cast<int>(text_position);
        }
    }

    const auto output_bytes = 8 * (match_count + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    std::array<std::uint8_t, kMaxOutputBytes> staged{};
    store_word(staged, 0, static_cast<std::int64_t>(match_count));
    for (std::size_t index = 0; index < match_count; ++index) {
        store_word(staged, index + 1, matches[index]);
    }
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}
