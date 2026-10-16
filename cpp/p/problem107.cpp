#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 40;
constexpr std::int64_t MAX_EDGE_WEIGHT = 999;

std::int64_t edge_weight(const std::int64_t *input, std::size_t left, std::size_t right) noexcept
{
    if (left == right) return -1;
    const auto row = left > right ? left : right;
    const auto column = left > right ? right : left;
    return input[1 + row * (row - 1) / 2 + column];
}
}

extern "C" std::int64_t problem107(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 1) return -1;
    const auto vertex_count_value = input[0];
    if (vertex_count_value < 1 || vertex_count_value > static_cast<std::int64_t>(MAX_VERTICES)) return -1;
    const auto vertex_count = static_cast<std::size_t>(vertex_count_value);
    if (length != 1 + vertex_count * (vertex_count - 1) / 2) return -1;

    std::int64_t total_weight = 0;
    for (std::size_t index = 1; index < length; ++index) {
        if (input[index] < -1 || input[index] > MAX_EDGE_WEIGHT) return -1;
        if (input[index] >= 0) total_weight += input[index];
    }

    std::array<bool, MAX_VERTICES> selected{};
    std::array<std::int64_t, MAX_VERTICES> best_weight{};
    best_weight.fill(MAX_EDGE_WEIGHT + 1);
    best_weight[0] = 0;
    std::int64_t tree_weight = 0;
    for (std::size_t iteration = 0; iteration < vertex_count; ++iteration) {
        auto next_vertex = vertex_count;
        std::int64_t next_weight = MAX_EDGE_WEIGHT + 1;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            if (!selected[vertex] && best_weight[vertex] < next_weight) {
                next_vertex = vertex;
                next_weight = best_weight[vertex];
            }
        }
        if (next_vertex == vertex_count) return -1;
        selected[next_vertex] = true;
        tree_weight += next_weight;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            if (selected[vertex]) continue;
            const auto weight = edge_weight(input, next_vertex, vertex);
            if (weight >= 0 && weight < best_weight[vertex]) best_weight[vertex] = weight;
        }
    }
    return total_weight - tree_weight;
}
