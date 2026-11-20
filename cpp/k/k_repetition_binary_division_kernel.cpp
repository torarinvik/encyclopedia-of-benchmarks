#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MaxN = 32, MaxK = 3, MaxInput = 35, MaxPeriods = 17;
constexpr int BitWords = 272, MaxFactors = 33, MaxOutput = 91400;

struct Search {
    int text[MaxN]{};
    int n = 0, budget = 0, factor_count = 0;
    int factor_start[MaxFactors]{}, factor_end[MaxFactors]{};
    std::uint64_t seen[BitWords]{};

    static int lp(const int *w, int size, int center, int period, int allowed) {
        const int left = center - period;
        const int limit = std::min(size - left, size - center);
        int errors = 0;
        for (int j = 0; j < limit; ++j) {
            if (w[left + j] != w[center + j] && ++errors > allowed) return j;
        }
        return limit;
    }

    static int ls(const int *w, int center, int period, int allowed) {
        const int limit = std::min(center - period, center);
        int errors = 0;
        for (int j = 0; j < limit; ++j) {
            if (w[center - period - 1 - j] != w[center - 1 - j]
                && ++errors > allowed) return j;
        }
        return limit;
    }

    void mark(int lo, int last_head, int start, int end, int period) {
        start += lo;
        end += lo;
        if (start <= lo || end >= n || end - start + 1 < 2 * period) return;
        if (start <= last_head + 1 && end >= last_head - 1) return;
        const int index = (start * MaxN + end) * MaxPeriods + period;
        seen[index / 64] |= std::uint64_t{1} << (index % 64);
    }

    void at_center(const int *w, int size, int center, int lo, int last_head) {
        if (center < 1 || center + 1 >= size) return;
        for (int p = 1; p <= center; ++p) {
            for (int k = 0; k <= budget; ++k) {
                const int forward = lp(w, size, center, p, k);
                const int backward = ls(w, center, p, budget - k);
                if (forward <= p && forward + backward >= p)
                    mark(lo, last_head, center - p - backward,
                         center + forward - 1, p);
            }
        }
        int reversed[MaxN]{};
        for (int i = 0; i < size; ++i) reversed[i] = w[size - 1 - i];
        const int rc = size - 1 - center;
        for (int p = 1; p <= rc; ++p) {
            for (int k = 0; k <= budget; ++k) {
                const int forward = lp(reversed, size, rc, p, k);
                const int backward = ls(reversed, rc, p, budget - k);
                if (forward <= p && forward + backward >= p) {
                    const int rs = rc - p - backward;
                    const int re = rc + forward - 1;
                    mark(lo, last_head, size - 1 - re, size - 1 - rs, p);
                }
            }
        }
    }

    void divide(int first, int last) {
        if (first >= last) return;
        const int mid = first + (last - first) / 2;
        const int lo = factor_start[first], hi = factor_end[last];
        const int center = factor_end[mid] - 1;
        const int last_head = factor_end[last] - 1;
        at_center(text + lo, hi - lo, center - lo, lo, last_head);
        divide(first, mid);
        divide(mid + 1, last);
    }
};

void encode_i64(std::uint8_t *out, std::size_t offset, std::uint64_t value) {
    for (std::size_t i = 0; i < 8; ++i) out[offset + i] = static_cast<std::uint8_t>(value >> (8 * i));
}
}

extern "C" std::int64_t k_repetition_binary_division_kernel(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > MaxInput) return -1;
    if (input[0] < 1 || input[0] > MaxN || input[1] < 0 || input[1] > MaxK) return -1;
    Search state;
    state.n = static_cast<int>(input[0]);
    state.budget = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(state.n + 2)) return -1;
    for (int i = 0; i < state.n; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 4) return -1;
        state.text[i] = static_cast<int>(input[i + 2]);
    }
    for (int i = 0; i + 1 < state.n; ++i)
        if (state.text[i] == state.text[state.n - 1]) return -1;

    int pos = 0;
    while (pos < state.n) {
        int best = 0;
        for (int earlier = 0; earlier < pos; ++earlier) {
            int match = 0;
            while (pos + match < state.n && earlier + match < state.n
                   && state.text[earlier + match] == state.text[pos + match]) ++match;
            best = std::max(best, match);
        }
        const int end = std::min(state.n, pos + best + 1);
        state.factor_start[state.factor_count] = pos;
        state.factor_end[state.factor_count++] = end;
        pos = end;
    }
    const int block_size = state.budget + 2;
    for (int first = 0; first < state.factor_count; first += block_size)
        state.divide(first, std::min(state.factor_count, first + block_size) - 1);

    std::int64_t records = 0;
    for (int start = 0; start < state.n; ++start)
        for (int len = 2; len <= state.n - start; ++len) {
            const int end = start + len - 1;
            for (int p = 1; p <= len / 2; ++p) {
                const int index = (start * MaxN + end) * MaxPeriods + p;
                if (state.seen[index / 64] & (std::uint64_t{1} << (index % 64))) ++records;
            }
        }
    const std::size_t written = 8 + static_cast<std::size_t>(records) * 32;
    if (written > MaxOutput) return -1;
    if (output == nullptr || capacity < written) return -2;
    encode_i64(output, 0, static_cast<std::uint64_t>(records));
    std::size_t offset = 8;
    for (int start = 0; start < state.n; ++start)
        for (int len = 2; len <= state.n - start; ++len) {
            const int end = start + len - 1;
            for (int p = 1; p <= len / 2; ++p) {
                const int index = (start * MaxN + end) * MaxPeriods + p;
                if (!(state.seen[index / 64] & (std::uint64_t{1} << (index % 64)))) continue;
                int mismatches = 0;
                for (int i = start; i <= end - p; ++i)
                    mismatches += state.text[i] != state.text[i + p];
                encode_i64(output, offset, start); offset += 8;
                encode_i64(output, offset, len); offset += 8;
                encode_i64(output, offset, p); offset += 8;
                encode_i64(output, offset, mismatches); offset += 8;
            }
        }
    return static_cast<std::int64_t>(written);
}
