#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MaxN = 32, MaxPattern = 16, MaxInput = 50, MaxOutput = 264;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) { out[at + static_cast<std::size_t>(i)] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
int suffix_compare(const std::array<std::int64_t, MaxN> &text, int a, int b, int n) {
    int k = 0; while (a + k < n && b + k < n) { if (text[a + k] < text[b + k]) return -1; if (text[a + k] > text[b + k]) return 1; ++k; }
    if (a + k == n && b + k == n) return 0; return a + k == n ? -1 : 1;
}
int compare_pattern(const std::array<std::int64_t, MaxN> &text, int start, int n,
                    const std::array<std::int64_t, MaxPattern> &pattern, int m, int offset, bool prefix_equal, int &matched) {
    matched = offset; while (matched < m && start + matched < n && text[start + matched] == pattern[matched]) ++matched;
    if (matched == m) { if (prefix_equal || start + matched == n) return 0; return 1; }
    if (start + matched == n) return -1; return text[start + matched] < pattern[matched] ? -1 : 1;
}
void build_intervals(int n, const std::array<int, MaxN> &lcp,
                     std::array<std::array<int, MaxN>, MaxN> &left_q,
                     std::array<std::array<int, MaxN>, MaxN> &right_q) {
    std::array<int, 2 * MaxN> lo_stack{}, hi_stack{}; int top = 0; lo_stack[top] = 0; hi_stack[top++] = n - 1;
    while (top) {
        const int lo = lo_stack[--top], hi = hi_stack[top]; if (hi - lo < 2) continue;
        const int mid = (lo + hi + 1) / 2; int q = n + 1;
        for (int k = lo; k < mid; ++k) if (lcp[k] < q) q = lcp[k]; left_q[lo][hi] = q;
        q = n + 1; for (int k = mid; k < hi; ++k) if (lcp[k] < q) q = lcp[k]; right_q[lo][hi] = q;
        if (hi - mid >= 2) { lo_stack[top] = mid; hi_stack[top++] = hi; }
        if (mid - lo >= 2) { lo_stack[top] = lo; hi_stack[top++] = mid; }
    }
}
int bound(const std::array<std::int64_t, MaxN> &text, int n,
          const std::array<std::int64_t, MaxPattern> &pattern, int m, const std::array<int, MaxN> &suffix,
          const std::array<std::array<int, MaxN>, MaxN> &left_q,
          const std::array<std::array<int, MaxN>, MaxN> &right_q, bool prefix_equal) {
    int l = 0, r = 0; const int first = compare_pattern(text, suffix[0], n, pattern, m, 0, prefix_equal, l);
    if (first > 0 || (!prefix_equal && first == 0)) return 0;
    const int last = compare_pattern(text, suffix[n - 1], n, pattern, m, 0, prefix_equal, r);
    if (last < 0 || (prefix_equal && last == 0)) return n;
    int lo = 0, hi = n - 1;
    while (hi - lo > 1) {
        const int mid = (lo + hi + 1) / 2; int cmp = 0, matched = 0;
        if (l == r) {
            cmp = compare_pattern(text, suffix[mid], n, pattern, m, l, prefix_equal, matched);
            if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; } else { lo = mid; l = matched; }
        } else if (l > r) {
            const int q = left_q[lo][hi];
            if (l < q) lo = mid; else if (l > q) { hi = mid; r = q; }
            else { cmp = compare_pattern(text, suffix[mid], n, pattern, m, l, prefix_equal, matched); if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; } else { lo = mid; l = matched; } }
        } else {
            const int q = right_q[lo][hi];
            if (r < q) hi = mid; else if (r > q) { lo = mid; l = q; }
            else { cmp = compare_pattern(text, suffix[mid], n, pattern, m, r, prefix_equal, matched); if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; } else { lo = mid; l = matched; } }
        }
    }
    return hi;
}
}

extern "C" std::int64_t suffix_array_lcp_search(const std::int64_t *v, std::size_t length,
                                                 std::uint8_t *output, std::size_t capacity) {
    if (!v || length < 3 || length > MaxInput || v[0] < 1 || v[0] > MaxN) return -1;
    const int n = static_cast<int>(v[0]); if (length < static_cast<std::size_t>(n + 2)) return -1;
    const int m = static_cast<int>(v[n + 1]); if (m < 1 || m > MaxPattern || length != static_cast<std::size_t>(n + m + 2)) return -1;
    std::array<std::int64_t, MaxN> text{}; std::array<std::int64_t, MaxPattern> pattern{};
    for (int i = 0; i < n; ++i) { text[i] = v[1 + i]; if (text[i] < 0 || text[i] > 127) return -1; }
    for (int i = 0; i < m; ++i) { pattern[i] = v[n + 2 + i]; if (pattern[i] < 0 || pattern[i] > 127) return -1; }
    std::array<int, MaxN> suffix{}; for (int i = 0; i < n; ++i) suffix[i] = i;
    for (int i = 1; i < n; ++i) { const int key = suffix[i]; int j = i; while (j > 0 && suffix_compare(text, key, suffix[j - 1], n) < 0) { suffix[j] = suffix[j - 1]; --j; } suffix[j] = key; }
    std::array<int, MaxN> lcp{};
    for (int i = 0; i + 1 < n; ++i) { int a = suffix[i], b = suffix[i + 1], k = 0; while (a + k < n && b + k < n && text[a + k] == text[b + k]) ++k; lcp[i] = k; }
    std::array<std::array<int, MaxN>, MaxN> left_q{}, right_q{}; build_intervals(n, lcp, left_q, right_q);
    const int first = bound(text, n, pattern, m, suffix, left_q, right_q, false);
    const int last = bound(text, n, pattern, m, suffix, left_q, right_q, true);
    const int count = last - first; const std::size_t bytes = 8 * static_cast<std::size_t>(count + 1);
    if (!output || capacity < bytes) return -2;
    std::uint8_t staged[MaxOutput]{}; put(staged, 0, count);
    for (int i = 0; i < count; ++i) put(staged, 8 * static_cast<std::size_t>(i + 1), suffix[first + i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i]; return static_cast<std::int64_t>(bytes);
}
