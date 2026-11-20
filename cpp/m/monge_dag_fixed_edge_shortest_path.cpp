#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32, side = max_n + 1, max_input = 531, max_frames = 64;
constexpr std::int64_t infinity = INT64_MAX / 4;
struct Frame { std::size_t row_begin, row_end, col_begin, col_end; };

void monge_layer(std::size_t n, std::size_t layer,
                 const std::array<std::int64_t, side> &dp,
                 const std::array<std::int64_t, side * side> &cost,
                 std::array<std::int64_t, side> &next) {
    std::array<Frame, max_frames> stack{};
    std::size_t stack_size = 0;
    stack[stack_size++] = {layer, n + 1, layer - 1, n};
    while (stack_size != 0) {
        const auto frame = stack[--stack_size];
        if (frame.row_begin >= frame.row_end) continue;
        const auto row = (frame.row_begin + frame.row_end) / 2;
        const auto upper = frame.col_end < row ? frame.col_end : row;
        auto best_column = frame.col_begin;
        auto best_value = infinity;
        for (auto column = frame.col_begin; column < upper; ++column) {
            if (dp[column] == infinity) continue;
            const auto candidate = dp[column] + cost[column * side + row];
            if (candidate < best_value) { best_value = candidate; best_column = column; }
        }
        next[row] = best_value;
        if (row + 1 < frame.row_end && best_column < frame.col_end)
            stack[stack_size++] = {row + 1, frame.row_end, best_column, frame.col_end};
        if (frame.row_begin < row && frame.col_begin < best_column + 1)
            stack[stack_size++] = {frame.row_begin, row, frame.col_begin, best_column + 1};
    }
}
}

extern "C" std::int64_t monge_dag_fixed_edge_shortest_path(const std::int64_t *input,
                                                             std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 1 || input[1] > input[0]) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto layers = static_cast<std::size_t>(input[1]);
    if (length != 2 + n * (n + 1) / 2) return -1;

    std::array<std::int64_t, side * side> cost{};
    std::size_t offset = 2;
    for (std::size_t u = 0; u < n; ++u) {
        for (std::size_t v = u + 1; v <= n; ++v) {
            const auto weight = input[offset++];
            if (weight < 0 || weight > 1'000'000) return -1;
            cost[u * side + v] = weight;
        }
    }
    for (std::size_t u = 0; u + 1 < n; ++u)
        for (std::size_t v = u + 2; v < n; ++v)
            if (cost[u * side + v] + cost[(u + 1) * side + v + 1] >
                cost[u * side + v + 1] + cost[(u + 1) * side + v]) return -1;

    std::array<std::int64_t, side> dp, next;
    dp.fill(infinity);
    dp[0] = 0;
    for (std::size_t layer = 1; layer <= layers; ++layer) {
        next.fill(infinity);
        monge_layer(n, layer, dp, cost, next);
        dp = next;
    }
    return dp[n];
}
