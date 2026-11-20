#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MaxN = 16, MaxQ = 8, TreeCap = 32, MaxOutput = 72;
struct Interval { std::int64_t low = 0, high = 0; int id = 0; };

void place_balanced(const std::array<Interval, MaxN>& sorted,
                    std::array<Interval, TreeCap>& tree,
                    std::array<bool, TreeCap>& used, int first, int last, int node) {
    if (first > last || node >= TreeCap) return;
    const int middle = first + (last - first) / 2;
    tree[static_cast<std::size_t>(node)] = sorted[static_cast<std::size_t>(middle)];
    used[static_cast<std::size_t>(node)] = true;
    place_balanced(sorted, tree, used, first, middle - 1, 2 * node + 1);
    place_balanced(sorted, tree, used, middle + 1, last, 2 * node + 2);
}

void write_i64_le(std::array<std::uint8_t, MaxOutput>& bytes, std::size_t offset,
                  std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b)
        bytes[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
} // namespace

extern "C" std::int64_t interval_tree_point_stabbing(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 43) return -1;
    const std::int64_t n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > MaxN || q64 < 0 || q64 > MaxQ) return -1;
    const int n = static_cast<int>(n64), q = static_cast<int>(q64);
    if (length != static_cast<std::size_t>(2 + 2 * n + q)) return -1;
    std::array<Interval, MaxN> sorted{};
    std::size_t at = 2;
    for (int i = 0; i < n; ++i) {
        const auto low = input[at++], high = input[at++];
        if (low < -32 || low > 32 || high < -32 || high > 32 || low > high) return -1;
        sorted[static_cast<std::size_t>(i)] = {low, high, i};
    }
    std::array<std::int64_t, MaxQ> points{};
    for (int i = 0; i < q; ++i) {
        points[static_cast<std::size_t>(i)] = input[at++];
        if (points[static_cast<std::size_t>(i)] < -32 || points[static_cast<std::size_t>(i)] > 32) return -1;
    }
    for (int i = 1; i < n; ++i) {
        const auto value = sorted[static_cast<std::size_t>(i)];
        int j = i;
        while (j > 0) {
            const auto& previous = sorted[static_cast<std::size_t>(j - 1)];
            const bool greater = previous.low > value.low ||
                (previous.low == value.low && previous.high > value.high) ||
                (previous.low == value.low && previous.high == value.high && previous.id > value.id);
            if (!greater) break;
            sorted[static_cast<std::size_t>(j)] = previous;
            --j;
        }
        sorted[static_cast<std::size_t>(j)] = value;
    }
    std::array<Interval, TreeCap> tree{};
    std::array<bool, TreeCap> used{};
    std::array<std::int64_t, TreeCap> maximum{};
    maximum.fill(INT64_MIN);
    if (n != 0) place_balanced(sorted, tree, used, 0, n - 1, 0);
    for (int node = TreeCap - 1; node >= 0; --node) {
        if (!used[static_cast<std::size_t>(node)]) continue;
        maximum[static_cast<std::size_t>(node)] = tree[static_cast<std::size_t>(node)].high;
        const int left = 2 * node + 1, right = left + 1;
        if (left < TreeCap && used[static_cast<std::size_t>(left)])
            maximum[static_cast<std::size_t>(node)] = std::max(maximum[static_cast<std::size_t>(node)], maximum[static_cast<std::size_t>(left)]);
        if (right < TreeCap && used[static_cast<std::size_t>(right)])
            maximum[static_cast<std::size_t>(node)] = std::max(maximum[static_cast<std::size_t>(node)], maximum[static_cast<std::size_t>(right)]);
    }
    std::array<std::int64_t, MaxQ> masks{};
    for (int qi = 0; qi < q; ++qi) {
        std::array<int, TreeCap> stack{};
        int top = 0;
        if (n != 0) stack[static_cast<std::size_t>(top++)] = 0;
        while (top != 0) {
            const int node = stack[static_cast<std::size_t>(--top)];
            if (!used[static_cast<std::size_t>(node)] || maximum[static_cast<std::size_t>(node)] < points[static_cast<std::size_t>(qi)]) continue;
            const int left = 2 * node + 1, right = left + 1;
            if (left < TreeCap && used[static_cast<std::size_t>(left)] && maximum[static_cast<std::size_t>(left)] >= points[static_cast<std::size_t>(qi)])
                stack[static_cast<std::size_t>(top++)] = left;
            const auto& current = tree[static_cast<std::size_t>(node)];
            if (current.low <= points[static_cast<std::size_t>(qi)] && points[static_cast<std::size_t>(qi)] <= current.high)
                masks[static_cast<std::size_t>(qi)] |= std::int64_t{1} << current.id;
            if (current.low <= points[static_cast<std::size_t>(qi)] && right < TreeCap && used[static_cast<std::size_t>(right)] && maximum[static_cast<std::size_t>(right)] >= points[static_cast<std::size_t>(qi)])
                stack[static_cast<std::size_t>(top++)] = right;
        }
    }
    const std::size_t bytes = static_cast<std::size_t>(q + 1) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::uint8_t, MaxOutput> staged{};
    write_i64_le(staged, 0, q);
    for (int i = 0; i < q; ++i) write_i64_le(staged, static_cast<std::size_t>(i + 1) * 8, masks[static_cast<std::size_t>(i)]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
