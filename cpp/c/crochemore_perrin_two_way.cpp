#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t kMaxTextLength = 64;
constexpr std::size_t kMaxPatternLength = 32;
constexpr std::size_t kMaxInputLength = 99;

struct Factorization {
    int critical;
    int period;
};

Factorization maximal_suffix(const std::vector<std::int64_t>& pattern, bool reverse_order) {
    int maximal = -1;
    int candidate = 0;
    int offset = 1;
    int period = 1;
    const int length = static_cast<int>(pattern.size());
    while (candidate + offset < length) {
        const auto a = pattern[static_cast<std::size_t>(candidate + offset)];
        const auto b = pattern[static_cast<std::size_t>(maximal + offset)];
        const bool precedes = reverse_order ? a > b : a < b;
        if (precedes) {
            candidate += offset;
            offset = 1;
            period = candidate - maximal;
        } else if (a == b) {
            if (offset != period) ++offset;
            else {
                candidate += period;
                offset = 1;
            }
        } else {
            maximal = candidate;
            candidate = maximal + 1;
            offset = 1;
            period = 1;
        }
    }
    return {maximal, period};
}

std::vector<std::int64_t> two_way(const std::vector<std::int64_t>& text,
                                  const std::vector<std::int64_t>& pattern) {
    const int n = static_cast<int>(text.size());
    const int m = static_cast<int>(pattern.size());
    std::vector<std::int64_t> matches;
    if (m == 0) {
        for (int i = 0; i <= n; ++i) matches.push_back(i);
        return matches;
    }
    if (m > n) return matches;

    const Factorization first = maximal_suffix(pattern, false);
    const Factorization second = maximal_suffix(pattern, true);
    const Factorization selected = first.critical > second.critical ? first : second;
    const int critical = selected.critical;
    const int period = selected.period;
    bool periodic = period + critical + 1 <= m;
    for (int i = 0; periodic && i <= critical; ++i)
        if (pattern[static_cast<std::size_t>(i)] != pattern[static_cast<std::size_t>(i + period)])
            periodic = false;
    const int shift = periodic ? period
        : std::max(critical, m - critical - 1) + 1;

    int memory = -1;
    for (int start = 0; start <= n - m;) {
        int index = periodic ? std::max(critical, memory) + 1 : critical + 1;
        while (index < m
               && pattern[static_cast<std::size_t>(index)]
                    == text[static_cast<std::size_t>(start + index)]) ++index;
        if (index >= m) {
            index = critical;
            while (index > memory
                   && pattern[static_cast<std::size_t>(index)]
                        == text[static_cast<std::size_t>(start + index)]) --index;
            if (index <= memory) matches.push_back(start);
            start += shift;
            memory = periodic ? m - period - 1 : -1;
        } else {
            start += index - critical;
            memory = -1;
        }
    }
    return matches;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}  // namespace

extern "C" std::int64_t crochemore_perrin_two_way(const std::int64_t* values,
                                                   std::size_t length,
                                                   std::uint8_t* output,
                                                   std::size_t capacity) {
    if (values == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(kMaxTextLength)
        || values[1] < 0 || values[1] > static_cast<std::int64_t>(kMaxPatternLength)) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    const auto m = static_cast<std::size_t>(values[1]);
    if (length != 2 + n + m) return -1;
    std::vector<std::int64_t> text(values + 2, values + 2 + n);
    std::vector<std::int64_t> pattern(values + 2 + n, values + 2 + n + m);
    if (std::any_of(text.begin(), text.end(), [](auto value) { return value < 0 || value > 255; })
        || std::any_of(pattern.begin(), pattern.end(), [](auto value) { return value < 0 || value > 255; }))
        return -1;
    const auto matches = two_way(text, pattern);
    const std::size_t output_bytes = matches.size() * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < matches.size(); ++i) store_i64_le(output, i * 8, matches[i]);
    return static_cast<std::int64_t>(output_bytes);
}
