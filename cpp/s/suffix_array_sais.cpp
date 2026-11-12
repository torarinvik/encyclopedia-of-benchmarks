#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr int kMaxTextLength = 32;
constexpr std::size_t kMaxInputLength = 34;
constexpr int kMaxAlphabet = 256;

void induce(const std::vector<int>& symbols, int upper,
            const std::vector<std::uint8_t>& is_s,
            const std::array<int, kMaxAlphabet + 2>& sum_s,
            const std::array<int, kMaxAlphabet + 2>& sum_l,
            const std::vector<int>& ordered_lms, std::vector<int>& suffixes) {
    const int n = static_cast<int>(symbols.size());
    suffixes.assign(n, -1);
    auto bucket = sum_s;
    for (int position : ordered_lms)
        suffixes[bucket[symbols[position]]++] = position;
    bucket = sum_l;
    for (int i = 0; i < n; ++i) {
        const int position = suffixes[i];
        if (position > 0 && !is_s[position - 1]) {
            const int symbol = symbols[position - 1];
            suffixes[bucket[symbol]++] = position - 1;
        }
    }
    bucket = sum_l;
    for (int i = n - 1; i >= 0; --i) {
        const int position = suffixes[i];
        if (position > 0 && is_s[position - 1]) {
            const int symbol = symbols[position - 1] + 1;
            suffixes[--bucket[symbol]] = position - 1;
        }
    }
    (void)upper;
}

bool same_lms_substring(const std::vector<int>& symbols,
                        const std::vector<std::uint8_t>& is_s,
                        const std::vector<int>& lms_map, int left, int right) {
    if (left == right) return true;
    for (int offset = 0;; ++offset) {
        const int a = left + offset;
        const int b = right + offset;
        if (a >= static_cast<int>(symbols.size()) || b >= static_cast<int>(symbols.size())
            || symbols[a] != symbols[b] || is_s[a] != is_s[b]) return false;
        const bool a_lms = offset > 0 && lms_map[a] >= 0;
        const bool b_lms = offset > 0 && lms_map[b] >= 0;
        if (a_lms || b_lms) return a_lms && b_lms;
    }
}

std::vector<int> sais(const std::vector<int>& symbols, int upper) {
    const int n = static_cast<int>(symbols.size());
    if (n == 0) return {};
    if (n <= 2) {
        std::vector<int> suffixes(n);
        for (int i = 0; i < n; ++i) suffixes[i] = i;
        if (n == 2 && symbols[0] >= symbols[1]) std::swap(suffixes[0], suffixes[1]);
        return suffixes;
    }

    std::vector<std::uint8_t> is_s(n, 0);
    is_s[n - 1] = 1;
    for (int i = n - 2; i >= 0; --i)
        is_s[i] = symbols[i] < symbols[i + 1]
            || (symbols[i] == symbols[i + 1] && is_s[i + 1]);

    std::vector<int> lms_map(n + 1, -1);
    std::vector<int> lms;
    for (int i = 1; i < n; ++i) {
        if (!is_s[i - 1] && is_s[i]) {
            lms_map[i] = static_cast<int>(lms.size());
            lms.push_back(i);
        }
    }

    std::array<int, kMaxAlphabet + 2> sum_s{};
    std::array<int, kMaxAlphabet + 2> sum_l{};
    for (int i = 0; i < n; ++i) {
        if (is_s[i]) ++sum_l[symbols[i] + 1];
        else ++sum_s[symbols[i]];
    }
    for (int symbol = 0; symbol <= upper; ++symbol) {
        sum_s[symbol] += sum_l[symbol];
        sum_l[symbol + 1] += sum_s[symbol];
    }

    std::vector<int> suffixes;
    induce(symbols, upper, is_s, sum_s, sum_l, lms, suffixes);
    std::vector<int> sorted_lms;
    for (int position : suffixes)
        if (position >= 0 && lms_map[position] >= 0) sorted_lms.push_back(position);

    std::vector<int> reduced(lms.size());
    int reduced_upper = 0;
    for (std::size_t i = 0; i < sorted_lms.size(); ++i) {
        if (i > 0 && !same_lms_substring(symbols, is_s, lms_map,
                                         sorted_lms[i - 1], sorted_lms[i]))
            ++reduced_upper;
        reduced[lms_map[sorted_lms[i]]] = reduced_upper;
    }
    std::vector<int> reduced_order;
    if (reduced_upper + 1 == static_cast<int>(reduced.size())) {
        reduced_order.resize(reduced.size());
        for (std::size_t i = 0; i < reduced.size(); ++i)
            reduced_order[reduced[i]] = static_cast<int>(i);
    } else {
        reduced_order = sais(reduced, reduced_upper);
    }
    std::vector<int> ordered_lms(reduced_order.size());
    for (std::size_t i = 0; i < reduced_order.size(); ++i)
        ordered_lms[i] = lms[reduced_order[i]];
    induce(symbols, upper, is_s, sum_s, sum_l, ordered_lms, suffixes);
    return suffixes;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}  // namespace

extern "C" std::int64_t suffix_array_sais(const std::int64_t* values,
                                           std::size_t length,
                                           std::uint8_t* output,
                                           std::size_t capacity) {
    if (values == nullptr || length < 1 || length > kMaxInputLength) return -1;
    if (values[0] < 0 || values[0] > kMaxTextLength) return -1;
    const int count = static_cast<int>(values[0]);
    if (length != static_cast<std::size_t>(count + 1)) return -1;
    for (int i = 0; i < count; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    const std::size_t output_bytes = static_cast<std::size_t>(count) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::vector<int> symbols(count + 1);
    for (int i = 0; i < count; ++i) symbols[i] = static_cast<int>(values[i + 1]) + 1;
    symbols[count] = 0;
    const std::vector<int> suffixes = sais(symbols, 256);
    std::size_t out = 0;
    for (int position : suffixes) {
        if (position == count) continue;
        store_i64_le(output, out++ * 8, position);
    }
    return static_cast<std::int64_t>(output_bytes);
}
