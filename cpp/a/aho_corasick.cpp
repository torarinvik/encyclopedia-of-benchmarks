#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PATTERNS = 16, MAX_PATTERN_LENGTH = 32, MAX_TEXT_LENGTH = 256;
constexpr std::size_t MAX_NODES = 1 + MAX_PATTERNS * MAX_PATTERN_LENGTH, ALPHABET = 128;
}

extern "C" std::int64_t aho_corasick(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 3 || input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_PATTERNS) || input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_TEXT_LENGTH)) return -1;
    const auto pattern_count = static_cast<std::size_t>(input[0]);
    if (length < 2 + pattern_count) return -1;
    std::array<std::size_t, MAX_PATTERNS> starts{};
    std::size_t text_start = 2 + pattern_count;
    for (std::size_t p = 0; p < pattern_count; ++p) {
        if (input[2 + p] < 1 || input[2 + p] > static_cast<std::int64_t>(MAX_PATTERN_LENGTH)) return -1;
        const auto size = static_cast<std::size_t>(input[2 + p]);
        if (text_start + size > length) return -1;
        starts[p] = text_start;
        for (std::size_t i = 0; i < size; ++i) if (input[starts[p] + i] < 1 || input[starts[p] + i] > 127) return -1;
        for (std::size_t q = 0; q < p; ++q) {
            if (input[2 + q] != static_cast<std::int64_t>(size)) continue;
            std::size_t i = 0;
            while (i < size && input[starts[q] + i] == input[starts[p] + i]) ++i;
            if (i == size) return -1;
        }
        text_start += size;
    }
    const auto text_length = static_cast<std::size_t>(input[1]);
    if (text_start + text_length != length) return -1;
    for (std::size_t i = 0; i < text_length; ++i) if (input[text_start + i] < 1 || input[text_start + i] > 127) return -1;
    const auto output_size = pattern_count * 8;
    if (output_capacity < output_size || output == nullptr) return -2;

    std::array<std::array<int, ALPHABET>, MAX_NODES> next;
    for (auto &row : next) row.fill(-1);
    std::array<int, MAX_NODES> failure{};
    std::array<int, MAX_NODES> terminal;
    terminal.fill(-1);
    std::size_t nodes = 1;
    for (std::size_t p = 0; p < pattern_count; ++p) {
        int state = 0;
        for (std::size_t i = 0; i < static_cast<std::size_t>(input[2 + p]); ++i) {
            const auto ch = static_cast<std::size_t>(input[starts[p] + i]);
            if (next[static_cast<std::size_t>(state)][ch] == -1) next[static_cast<std::size_t>(state)][ch] = static_cast<int>(nodes++);
            state = next[static_cast<std::size_t>(state)][ch];
        }
        terminal[static_cast<std::size_t>(state)] = static_cast<int>(p);
    }
    std::array<int, MAX_NODES> queue{};
    std::size_t head = 0, tail = 0;
    for (std::size_t ch = 1; ch < ALPHABET; ++ch) if (next[0][ch] != -1) queue[tail++] = next[0][ch];
    while (head < tail) {
        const int state = queue[head++];
        for (std::size_t ch = 1; ch < ALPHABET; ++ch) {
            const int child = next[static_cast<std::size_t>(state)][ch];
            if (child == -1) continue;
            int suffix = failure[static_cast<std::size_t>(state)];
            while (suffix != 0 && next[static_cast<std::size_t>(suffix)][ch] == -1) suffix = failure[static_cast<std::size_t>(suffix)];
            if (next[static_cast<std::size_t>(suffix)][ch] != -1) suffix = next[static_cast<std::size_t>(suffix)][ch];
            failure[static_cast<std::size_t>(child)] = suffix;
            queue[tail++] = child;
        }
    }
    std::array<std::int64_t, MAX_PATTERNS> counts{};
    int state = 0;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto ch = static_cast<std::size_t>(input[text_start + i]);
        while (state != 0 && next[static_cast<std::size_t>(state)][ch] == -1) state = failure[static_cast<std::size_t>(state)];
        if (next[static_cast<std::size_t>(state)][ch] != -1) state = next[static_cast<std::size_t>(state)][ch];
        for (int match = state; match != 0; match = failure[static_cast<std::size_t>(match)])
            if (terminal[static_cast<std::size_t>(match)] >= 0) ++counts[static_cast<std::size_t>(terminal[static_cast<std::size_t>(match)])];
    }
    for (std::size_t p = 0; p < pattern_count; ++p)
        for (std::size_t b = 0; b < 8; ++b) output[p * 8 + b] = static_cast<std::uint8_t>((static_cast<std::uint64_t>(counts[p]) >> (8 * b)) & 0xff);
    return static_cast<std::int64_t>(output_size);
}
