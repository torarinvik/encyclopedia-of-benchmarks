#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 64, K = 4, InputLimit = 67, OutputLimit = 320, Levels = 7;

bool pairLess(int left, int right, int width, const std::array<int, N> &rank, int n) {
    if (rank[left] != rank[right]) return rank[left] < rank[right];
    const int a = left + width < n ? rank[left + width] : -1;
    const int b = right + width < n ? rank[right + width] : -1;
    return a < b;
}

int lce(int a, int b, int n, const std::array<int, N> &inverse,
        const std::array<std::array<int, N>, Levels> &rmq,
        const std::array<int, N + 1> &logs) {
    if (a >= n || b >= n) return 0;
    if (a == b) return n - a;
    int left = inverse[a], right = inverse[b];
    if (left > right) std::swap(left, right);
    ++left;
    const int count = right - left + 1, level = logs[count], span = 1 << level;
    return std::min(rmq[level][left], rmq[level][right - span + 1]);
}
}

extern "C" std::int64_t k_mismatch_longest_extension_table(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > InputLimit) return -1;
    if (input[0] < 1 || input[0] > N || input[1] < 0 || input[1] > K) return -1;
    const int n = static_cast<int>(input[0]), budget = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(n + 2)) return -1;

    std::array<int, N> text{}, suffixes{}, rank{}, nextRank{}, inverse{}, lcp{};
    std::array<std::array<int, N>, Levels> rmq{};
    std::array<int, N + 1> logs{};
    std::array<std::uint8_t, OutputLimit> staged{};
    for (int i = 0; i < n; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 25) return -1;
        text[i] = static_cast<int>(input[i + 2]);
        suffixes[i] = i;
        rank[i] = text[i];
    }

    for (int width = 1; width < n; width *= 2) {
        for (int i = 1; i < n; ++i) {
            const int key = suffixes[i];
            int j = i;
            while (j > 0 && pairLess(key, suffixes[j - 1], width, rank, n)) {
                suffixes[j] = suffixes[j - 1];
                --j;
            }
            suffixes[j] = key;
        }
        int classes = 0;
        nextRank[suffixes[0]] = 0;
        for (int i = 1; i < n; ++i) {
            const int a = suffixes[i - 1], b = suffixes[i];
            if (rank[a] != rank[b]
                || (a + width < n ? rank[a + width] : -1)
                    != (b + width < n ? rank[b + width] : -1)) ++classes;
            nextRank[b] = classes;
        }
        rank = nextRank;
        if (classes == n - 1 || width > n / 2) break;
    }

    for (int i = 0; i < n; ++i) inverse[suffixes[i]] = i;
    int matched = 0;
    for (int start = 0; start < n; ++start) {
        const int order = inverse[start];
        if (order == 0) { matched = 0; continue; }
        const int other = suffixes[order - 1];
        while (start + matched < n && other + matched < n && text[start + matched] == text[other + matched]) ++matched;
        lcp[order] = matched;
        if (matched > 0) --matched;
    }
    rmq[0] = lcp;
    for (int level = 1; level < Levels; ++level) {
        const int span = 1 << level, half = span >> 1;
        for (int i = 0; i + span <= n; ++i)
            rmq[level][i] = std::min(rmq[level - 1][i], rmq[level - 1][i + half]);
    }
    for (int count = 2; count <= n; ++count) logs[count] = logs[count / 2] + 1;

    int written = 0;
    for (int p = 0; p < n; ++p) {
        const int limit = n - p;
        int extension = std::min(limit, lce(0, p, n, inverse, rmq, logs));
        staged[written++] = static_cast<std::uint8_t>(extension);
        for (int k = 1; k <= budget; ++k) {
            if (extension < limit)
                extension = std::min(limit, extension + 1 + lce(extension + 1, p + extension + 1, n, inverse, rmq, logs));
            staged[written++] = static_cast<std::uint8_t>(extension);
        }
    }
    if (written > OutputLimit) return -1;
    if (output == nullptr || capacity < static_cast<std::size_t>(written)) return -2;
    for (int i = 0; i < written; ++i) output[i] = staged[i];
    return written;
}
