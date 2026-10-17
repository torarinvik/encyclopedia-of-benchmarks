#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 16;
constexpr std::size_t kMaxInputValues = 257;
constexpr std::int64_t kMaxWeight = 1'000'000;

std::int64_t stoer_wagner_impl(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > kMaxInputValues) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 2 || n_value > kMaxN) return -1;
    const int n = static_cast<int>(n_value);
    if (length != static_cast<std::size_t>(1 + n * n)) return -1;

    std::int64_t graph[kMaxN][kMaxN]{};
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            const std::int64_t weight = input[1 + i * n + j];
            if (weight < 0 || weight > kMaxWeight) return -1;
            graph[i][j] = weight;
        }
    }
    for (int i = 0; i < n; ++i) {
        if (graph[i][i] != 0) return -1;
        for (int j = i + 1; j < n; ++j) {
            if (graph[i][j] != graph[j][i]) return -1;
        }
    }

    bool merged[kMaxN]{};
    std::int64_t min_cut = 120'000'001;
    for (int phase = 0; phase < n - 1; ++phase) {
        bool in_set[kMaxN]{};
        std::int64_t weights[kMaxN]{};
        int previous = -1;
        int last = -1;
        for (int step = 0; step < n - phase; ++step) {
            int current = -1;
            std::int64_t max_weight = -1;
            for (int vertex = 0; vertex < n; ++vertex) {
                if (!merged[vertex] && !in_set[vertex] && weights[vertex] > max_weight) {
                    max_weight = weights[vertex];
                    current = vertex;
                }
            }
            if (current < 0) break;
            in_set[current] = true;
            previous = last;
            last = current;
            for (int vertex = 0; vertex < n; ++vertex) {
                if (!merged[vertex] && !in_set[vertex]) {
                    weights[vertex] += graph[current][vertex];
                }
            }
        }
        if (last < 0 || previous < 0) return -1;
        if (weights[last] < min_cut) min_cut = weights[last];
        for (int vertex = 0; vertex < n; ++vertex) {
            graph[previous][vertex] += graph[last][vertex];
            graph[vertex][previous] = graph[previous][vertex];
        }
        merged[last] = true;
    }
    return min_cut;
}
}  // namespace

extern "C" std::int64_t stoer_wagner(const std::int64_t *input, std::size_t length) noexcept
{
    return stoer_wagner_impl(input, length);
}
