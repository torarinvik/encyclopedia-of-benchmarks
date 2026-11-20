#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 32, max_input = 34, max_output = 512;

bool suffix_less(const std::int64_t* text, std::size_t n, std::size_t a, std::size_t b) {
    while (a < n && b < n) {
        if (text[a] != text[b]) return text[a] < text[b];
        ++a; ++b;
    }
    return a == n && b != n;
}

std::size_t lcp(const std::int64_t* text, std::size_t n, std::int64_t source, std::size_t target) {
    if (source < 0) return 0;
    std::size_t length = 0, p = static_cast<std::size_t>(source);
    while (target + length < n && text[p + length] == text[target + length]) ++length;
    return length;
}

void put64(std::uint8_t* out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t lz77_lpf_suffix_array(const std::int64_t* input, std::size_t length,
                                               std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    const auto* text = input + 1;
    std::size_t sa[max_text], inverse[max_text], stack[max_text];
    std::int64_t previous[max_text], following[max_text];
    for (std::size_t i = 0; i < n; ++i) sa[i] = i;
    for (std::size_t i = 1; i < n; ++i) {
        const auto value = sa[i]; auto j = i;
        while (j > 0 && suffix_less(text, n, value, sa[j - 1])) { sa[j] = sa[j - 1]; --j; }
        sa[j] = value;
    }
    for (std::size_t r = 0; r < n; ++r) inverse[sa[r]] = r;
    std::size_t top = 0;
    for (std::size_t r = 0; r < n; ++r) {
        while (top > 0 && sa[stack[top - 1]] > sa[r]) --top;
        previous[r] = top > 0 ? static_cast<std::int64_t>(stack[top - 1]) : -1;
        stack[top++] = r;
    }
    top = 0;
    for (std::size_t rr = n; rr > 0; --rr) {
        const auto r = rr - 1;
        while (top > 0 && sa[stack[top - 1]] > sa[r]) --top;
        following[r] = top > 0 ? static_cast<std::int64_t>(stack[top - 1]) : -1;
        stack[top++] = r;
    }
    std::uint8_t staged[max_output]{};
    std::size_t pairs = 0, pos = 0;
    while (pos < n) {
        const auto r = inverse[pos];
        const auto psv = previous[r] >= 0 ? static_cast<std::int64_t>(sa[static_cast<std::size_t>(previous[r])]) : -1;
        const auto nsv = following[r] >= 0 ? static_cast<std::int64_t>(sa[static_cast<std::size_t>(following[r])]) : -1;
        const auto lp = lcp(text, n, psv, pos), ln = lcp(text, n, nsv, pos);
        auto source = ln > lp ? nsv : psv;
        const auto match = ln > lp ? ln : lp;
        if (match == 0) source = -1;
        put64(staged, pairs * 16, source); put64(staged, pairs * 16 + 8, static_cast<std::int64_t>(match));
        ++pairs; pos += match > 0 ? match : 1;
    }
    const auto bytes = pairs * 16;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
