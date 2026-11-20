#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t kText = 16, kParens = 8, kRows = 1u << kParens, kOutput = 4354;
unsigned bit_count(unsigned x) { unsigned n = 0; for (; x; x >>= 1) n += x & 1u; return n; }
bool is_balanced(const std::uint8_t *s, std::size_t n) {
    int depth = 0;
    for (std::size_t i = 0; i < n; ++i) {
        if (s[i] == '(') ++depth;
        else if (s[i] == ')' && --depth < 0) return false;
    }
    return depth == 0;
}
bool less_row(const std::uint8_t *a, std::size_t an,
              const std::uint8_t *b, std::size_t bn) {
    const auto n = an < bn ? an : bn;
    const int c = std::memcmp(a, b, n);
    return c < 0 || (c == 0 && an < bn);
}
}

extern "C" std::int64_t minimum_parenthesis_removal_bfs(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kText + 1) return -1;
    const auto n64 = input[0];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(kText) || length != static_cast<std::size_t>(n64) + 1) return -1;
    const auto n = static_cast<std::size_t>(n64);
    std::array<std::uint8_t, kText> text{};
    std::array<std::uint8_t, kParens> positions{};
    std::size_t p = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto v = input[i + 1];
        if (v == '(' || v == ')') {
            if (p == kParens) return -1;
            positions[p++] = static_cast<std::uint8_t>(i);
        } else if (v < 'a' || v > 'z') return -1;
        text[i] = static_cast<std::uint8_t>(v);
    }
    std::array<std::array<std::uint8_t, kText>, kRows> rows{};
    std::array<std::uint8_t, kRows> sizes{};
    std::size_t count = 0;
    const unsigned states = 1u << p;
    for (std::size_t d = 0; d <= p && count == 0; ++d) {
        for (unsigned mask = 0; mask < states; ++mask) {
            if (bit_count(mask) != d) continue;
            std::array<std::uint8_t, kText> candidate{};
            std::size_t used = 0, ord = 0;
            for (std::size_t i = 0; i < n; ++i) {
                const bool at_paren = ord < p && positions[ord] == i;
                const bool remove = at_paren && (mask & (1u << ord)) != 0;
                if (at_paren) ++ord;
                if (!remove) candidate[used++] = text[i];
            }
            if (!is_balanced(candidate.data(), used)) continue;
            bool duplicate = false;
            for (std::size_t r = 0; r < count; ++r)
                if (sizes[r] == used && std::memcmp(rows[r].data(), candidate.data(), used) == 0) duplicate = true;
            if (!duplicate) { rows[count] = candidate; sizes[count++] = static_cast<std::uint8_t>(used); }
        }
    }
    if (count == 0) { rows[0][0] = 0; sizes[0] = 0; count = 1; }
    for (std::size_t i = 1; i < count; ++i) {
        auto key = rows[i]; const auto key_size = sizes[i]; std::size_t j = i;
        while (j > 0 && less_row(key.data(), key_size, rows[j - 1].data(), sizes[j - 1])) {
            rows[j] = rows[j - 1]; sizes[j] = sizes[j - 1]; --j;
        }
        rows[j] = key; sizes[j] = key_size;
    }
    std::size_t needed = 2;
    for (std::size_t i = 0; i < count; ++i) needed += 1 + sizes[i];
    if (needed > kOutput) return -1;
    if (output == nullptr || capacity < needed) return -2;
    output[0] = static_cast<std::uint8_t>(count); output[1] = static_cast<std::uint8_t>(count >> 8);
    std::size_t pos = 2;
    for (std::size_t i = 0; i < count; ++i) {
        output[pos++] = sizes[i];
        std::memcpy(output + pos, rows[i].data(), sizes[i]); pos += sizes[i];
    }
    return static_cast<std::int64_t>(pos);
}
