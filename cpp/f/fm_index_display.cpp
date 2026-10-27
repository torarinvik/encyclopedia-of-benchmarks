#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TEXT = 32, MAX_INPUT = 36;
constexpr std::size_t ALPHABET = 5;
bool suffix_less(const std::int64_t *text, std::size_t n, std::size_t a, std::size_t b) {
    while (a < n && b < n) {
        if (text[a] != text[b]) return text[a] < text[b];
        ++a; ++b;
    }
    return a == n && b != n;
}
}

extern "C" std::int64_t fm_index_display(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 5 || length > MAX_INPUT) return -1;
    const auto n0 = input[0];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(MAX_TEXT) || length != static_cast<std::size_t>(n0) + 4) return -1;
    const auto n = static_cast<std::size_t>(n0);
    const auto left0 = input[n + 1], right0 = input[n + 2], stride0 = input[n + 3];
    if (left0 < 0 || right0 < left0 || right0 >= n0 || stride0 < 1 || stride0 > n0) return -1;
    const auto left = static_cast<std::size_t>(left0), right = static_cast<std::size_t>(right0);
    const auto stride = static_cast<std::size_t>(stride0), size = n + 1;
    std::int64_t text[MAX_TEXT + 1]{};
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 1 || input[i + 1] > 4) return -1;
        text[i] = input[i + 1];
    }
    text[n] = 0;
    std::size_t sa[MAX_TEXT + 1];
    for (std::size_t i = 0; i < size; ++i) sa[i] = i;
    for (std::size_t i = 1; i < size; ++i) {
        const auto key = sa[i];
        auto j = i;
        while (j > 0 && suffix_less(text, size, key, sa[j - 1])) { sa[j] = sa[j - 1]; --j; }
        sa[j] = key;
    }
    std::size_t isa[MAX_TEXT + 1], freq[ALPHABET]{};
    std::int64_t bwt[MAX_TEXT + 1];
    for (std::size_t row = 0; row < size; ++row) {
        const auto pos = sa[row];
        isa[pos] = row;
        bwt[row] = text[(pos + size - 1) % size];
        ++freq[static_cast<std::size_t>(bwt[row])];
    }
    std::size_t first[ALPHABET], sum = 0;
    for (std::size_t c = 0; c < ALPHABET; ++c) { first[c] = sum; sum += freq[c]; }
    std::size_t seen[ALPHABET]{}, lf[MAX_TEXT + 1];
    for (std::size_t row = 0; row < size; ++row) {
        const auto c = static_cast<std::size_t>(bwt[row]);
        lf[row] = first[c] + seen[c]++;
    }
    std::size_t sampled_isa[MAX_TEXT + 1];
    bool sampled[MAX_TEXT + 1]{};
    for (std::size_t pos = 0; pos < n; ++pos) if ((pos + 1) % stride == 0) { sampled[pos] = true; sampled_isa[pos] = isa[pos]; }
    sampled[n] = true; sampled_isa[n] = isa[n];
    auto sample = ((right + 1) / stride + 1) * stride - 1;
    if (sample > n) sample = n;
    if (!sampled[sample]) return -1;
    auto row = sampled_isa[sample], current = sample;
    while (current > right + 1) { row = lf[row]; --current; }
    std::uint8_t reversed[MAX_TEXT];
    std::size_t count = 0;
    while (current > left) { reversed[count++] = static_cast<std::uint8_t>(bwt[row]); row = lf[row]; --current; }
    if (count != right - left + 1) return -1;
    if (!output || capacity < count) return -2;
    for (std::size_t i = 0; i < count; ++i) output[i] = reversed[count - 1 - i];
    return static_cast<std::int64_t>(count);
}
