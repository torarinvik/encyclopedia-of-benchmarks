#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 24, K = 3, InputMax = 27, ContextMax = 48;
constexpr int FactorMax = 25, PeriodSlots = 13, BitWords = 117, OutputMax = 39112;

struct Pass {
    std::array<int, N> word{};
    std::array<int, FactorMax> begin{};
    std::array<int, FactorMax> end{};
    std::array<std::uint64_t, BitWords> marks{};
    int size = 0;
    int budget = 0;
    int factors = 0;

    static int extend_right(const int* x, int count, int center, int period, int allowance) {
        int errors = 0;
        const int limit = std::min(count - (center - period), count - center);
        for (int d = 0; d < limit; ++d) {
            if (x[center - period + d] != x[center + d] && ++errors > allowance) return d;
        }
        return limit;
    }

    static int extend_left(const int* x, int center, int period, int allowance) {
        int errors = 0;
        const int limit = std::min(center - period, center);
        for (int d = 0; d < limit; ++d) {
            if (x[center - period - 1 - d] != x[center - 1 - d] && ++errors > allowance) return d;
        }
        return limit;
    }

    void record(int base, int count, int center, int next, int left, int right, int period) {
        if (left < 0 || right >= count || right - left + 1 < 2 * period) return;
        if (left > center + 1 || right < center - 1) return;
        if (left <= next + 1 && right >= next - 1) return;
        const int a = base + left, b = base + right;
        if (a < 0 || b >= size) return;
        const int key = (a * N + b) * PeriodSlots + period;
        marks[key / 64] |= std::uint64_t{1} << (key % 64);
    }

    void inspect_center(const int* x, int count, int base, int center, int next) {
        if (center < 1 || center + 1 >= count) return;
        for (int p = 1; p <= center; ++p) {
            for (int split = 0; split <= budget; ++split) {
                const int r = extend_right(x, count, center, p, split);
                const int l = extend_left(x, center, p, budget - split);
                if (r <= p && r + l >= p) record(base, count, center, next, center - p - l,
                                                  center + r - 1, p);
            }
        }
        std::array<int, ContextMax> reverse{};
        for (int i = 0; i < count; ++i) reverse[i] = x[count - 1 - i];
        const int rc = count - 1 - center;
        for (int p = 1; p <= rc; ++p) {
            for (int split = 0; split <= budget; ++split) {
                const int r = extend_right(reverse.data(), count, rc, p, split);
                const int l = extend_left(reverse.data(), rc, p, budget - split);
                if (r <= p && r + l >= p) {
                    const int rs = rc - p - l, re = rc + r - 1;
                    record(base, count, center, next, count - 1 - re, count - 1 - rs, p);
                }
            }
        }
    }

    void make_factors() {
        int pos = 0;
        while (pos < size) {
            int match_best = 0;
            for (int earlier = 0; earlier < pos; ++earlier) {
                int matched = 0;
                while (pos + matched < size && earlier + matched < size &&
                       word[earlier + matched] == word[pos + matched]) ++matched;
                match_best = std::max(match_best, matched);
            }
            begin[factors] = pos;
            end[factors] = std::min(size, pos + match_best + 1);
            pos = end[factors++];
        }
    }

    void run_heads() {
        const int width = budget + 2;
        const int blocks = (factors + width - 1) / width;
        for (int b = 0; b + 1 < blocks; ++b) {
            const int first = b * width;
            const int first_end = std::min(factors, first + width);
            const int second_end = std::min(factors, first_end + width);
            const int head = end[first_end - 1] - 1;
            const int next = end[second_end - 1] - 1;
            const int pair_begin = begin[first], pair_end = end[second_end - 1];
            const int pair_size = pair_end - pair_begin;
            const int context_begin = std::max(0, pair_begin - pair_size);
            std::array<int, ContextMax> local{};
            const int local_size = pair_end - context_begin;
            for (int i = 0; i < local_size; ++i) local[i] = word[context_begin + i];
            inspect_center(local.data(), local_size, context_begin, head - context_begin,
                           next - context_begin);
        }
    }

    bool marked(int start, int end_pos, int period) const {
        const int key = (start * N + end_pos) * PeriodSlots + period;
        return (marks[key / 64] & (std::uint64_t{1} << (key % 64))) != 0;
    }
};

void store64(std::uint8_t* out, std::size_t at, std::uint64_t value) {
    for (std::size_t j = 0; j < 8; ++j) out[at + j] = static_cast<std::uint8_t>(value >> (8 * j));
}
} // namespace

extern "C" std::int64_t k_repetition_block_head_pair_pass(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > InputMax) return -1;
    if (input[0] < 1 || input[0] > N || input[1] < 0 || input[1] > K) return -1;
    const int n = static_cast<int>(input[0]), budget = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(n + 2)) return -1;
    Pass state;
    state.size = n;
    state.budget = budget;
    for (int i = 0; i < n; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 4) return -1;
        state.word[i] = static_cast<int>(input[i + 2]);
    }
    for (int i = 0; i + 1 < n; ++i) if (state.word[i] == state.word[n - 1]) return -1;
    state.make_factors();
    state.run_heads();

    std::size_t count = 0;
    for (int start = 0; start < n; ++start)
        for (int len = 2; len <= n - start; ++len) {
            const int finish = start + len - 1;
            for (int p = 1; p <= len / 2; ++p) if (state.marked(start, finish, p)) ++count;
        }
    const std::size_t bytes = 8 + count * 32;
    if (bytes > OutputMax) return -1;
    if (output == nullptr || capacity < bytes) return -2;
    store64(output, 0, count);
    std::size_t cursor = 8;
    for (int start = 0; start < n; ++start)
        for (int len = 2; len <= n - start; ++len) {
            const int finish = start + len - 1;
            for (int p = 1; p <= len / 2; ++p) {
                if (!state.marked(start, finish, p)) continue;
                int errors = 0;
                for (int i = start; i <= finish - p; ++i) errors += state.word[i] != state.word[i + p];
                store64(output, cursor, start); cursor += 8;
                store64(output, cursor, len); cursor += 8;
                store64(output, cursor, p); cursor += 8;
                store64(output, cursor, errors); cursor += 8;
            }
        }
    return static_cast<std::int64_t>(bytes);
}
