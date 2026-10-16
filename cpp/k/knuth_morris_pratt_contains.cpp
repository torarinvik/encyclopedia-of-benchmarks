/* Return whether a pattern occurs using Knuth-Morris-Pratt matching. */
#include <cstddef>
#include <cstdint>

extern "C" int64_t knuth_morris_pratt_contains(const int64_t *packed, std::size_t length)
{
    if (packed == nullptr || length < 2 || length > 8194) return -1;
    if (packed[0] < 0 || packed[0] > 4096 || packed[1] < 0 || packed[1] > 4096) return -1;
    const std::size_t text_length = static_cast<std::size_t>(packed[0]);
    const std::size_t pattern_length = static_cast<std::size_t>(packed[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t index = 0; index < text_length + pattern_length; ++index)
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    if (pattern_length == 0) return 0;

    const std::size_t pattern_start = 2 + text_length;
    std::size_t prefix[4096];
    prefix[0] = 0;
    for (std::size_t index = 1, matched = 0; index < pattern_length; ++index) {
        while (matched > 0 && packed[pattern_start + index] != packed[pattern_start + matched])
            matched = prefix[matched - 1];
        if (packed[pattern_start + index] == packed[pattern_start + matched]) ++matched;
        prefix[index] = matched;
    }

    for (std::size_t index = 0, matched = 0; index < text_length; ++index) {
        while (matched > 0 && packed[2 + index] != packed[pattern_start + matched])
            matched = prefix[matched - 1];
        if (packed[2 + index] == packed[pattern_start + matched]) ++matched;
        if (matched == pattern_length) return 1;
    }
    return 0;
}
