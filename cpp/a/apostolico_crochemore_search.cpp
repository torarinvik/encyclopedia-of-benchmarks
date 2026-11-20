#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 4096;
constexpr std::size_t max_pattern_length = 128;
constexpr std::size_t max_parseable_length = 4227;
constexpr std::size_t pattern_storage = max_pattern_length + 1;

void preprocess(const std::int64_t *pattern, std::size_t pattern_length,
                std::int64_t *kmp_next) noexcept {
    std::int64_t i = 0;
    std::int64_t j = -1;
    kmp_next[0] = -1;
    while (static_cast<std::size_t>(i) < pattern_length) {
        while (j > -1 && pattern[i] != pattern[j]) j = kmp_next[j];
        ++i;
        ++j;
        if (pattern[i] == pattern[j]) kmp_next[i] = kmp_next[j];
        else kmp_next[i] = j;
    }
}
} // namespace

extern "C" std::int64_t apostolico_crochemore_search(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_length) {
        return -1;
    }

    const std::int64_t text_length_value = input[0];
    const std::int64_t pattern_length_value = input[1];
    if (text_length_value < 0
        || text_length_value > static_cast<std::int64_t>(max_text_length)
        || pattern_length_value < 1
        || pattern_length_value > static_cast<std::int64_t>(max_pattern_length)) {
        return -1;
    }
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto pattern_length = static_cast<std::size_t>(pattern_length_value);
    if (length != 2 + text_length + pattern_length) return -1;

    const std::size_t pattern_start = 2 + text_length;
    std::int64_t pattern[pattern_storage]{};
    for (std::size_t index = 0; index < text_length; ++index) {
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;
    }
    for (std::size_t index = 0; index < pattern_length; ++index) {
        const std::int64_t byte = input[pattern_start + index];
        if (byte < 0 || byte > 3) return -1;
        pattern[index] = byte;
    }
    pattern[pattern_length] = 4;

    std::int64_t kmp_next[pattern_storage]{};
    preprocess(pattern, pattern_length, kmp_next);

    std::int64_t ell = 1;
    while (static_cast<std::size_t>(ell) < pattern_length
           && pattern[ell - 1] == pattern[ell]) {
        ++ell;
    }
    if (static_cast<std::size_t>(ell) == pattern_length) ell = 0;

    std::int64_t match_count = 0;
    std::int64_t sum_offsets = 0;
    std::int64_t xor_offsets = 0;
    if (text_length >= pattern_length) {
        std::int64_t i = ell;
        std::int64_t j = 0;
        std::int64_t k = 0;
        while (static_cast<std::size_t>(j) <= text_length - pattern_length) {
            while (static_cast<std::size_t>(i) < pattern_length
                   && pattern[i] == input[2 + static_cast<std::size_t>(j)
                                           + static_cast<std::size_t>(i)]) {
                ++i;
            }
            if (static_cast<std::size_t>(i) >= pattern_length) {
                while (static_cast<std::size_t>(k) < static_cast<std::size_t>(ell)
                       && pattern[k] == input[2 + static_cast<std::size_t>(j)
                                               + static_cast<std::size_t>(k)]) {
                    ++k;
                }
                if (k >= ell) {
                    ++match_count;
                    sum_offsets += j;
                    xor_offsets ^= j;
                }
            }

            j += i - kmp_next[i];
            if (i == ell) {
                if (k > 0) --k;
            } else if (kmp_next[i] <= ell) {
                k = kmp_next[i] > 0 ? kmp_next[i] : 0;
                i = ell;
            } else {
                k = ell;
                i = kmp_next[i];
            }
        }
    }

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets;
}
