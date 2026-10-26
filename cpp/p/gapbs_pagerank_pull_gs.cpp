#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gapbs_pagerank_pull_gs(const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::size_t max_n = 8, max_iters = 20;
    if (input == nullptr || length < 6 || length > 2 + max_n * max_n) return -1;
    const auto n64 = input[0], iterations64 = input[1];
    if (n64 < 2 || n64 > static_cast<std::int64_t>(max_n) || iterations64 < 0 || iterations64 > static_cast<std::int64_t>(max_iters)) return -1;
    const auto n = static_cast<std::size_t>(n64), iterations = static_cast<std::size_t>(iterations64);
    if (length != 2 + n * n) return -1;
    std::uint8_t matrix[max_n * max_n]{};
    std::size_t outdegree[max_n]{};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const auto value = input[2 + row * n + column];
            if ((value != 0 && value != 1) || (row == column && value != 0)) return -1;
            matrix[row * n + column] = static_cast<std::uint8_t>(value);
            outdegree[row] += static_cast<std::size_t>(value);
        }
        if (outdegree[row] == 0) return -1;
    }
    constexpr float damping = 0.85f;
    const float init_score = 1.0f / static_cast<float>(n);
    const float base_score = (1.0f - damping) / static_cast<float>(n);
    float scores[max_n]{}, outgoing[max_n]{};
    for (std::size_t node = 0; node < n; ++node) {
        scores[node] = init_score;
        outgoing[node] = init_score / static_cast<float>(outdegree[node]);
    }
    for (std::size_t iteration = 0; iteration < iterations; ++iteration) {
        for (std::size_t target = 0; target < n; ++target) {
            float incoming = 0.0f;
            for (std::size_t source = 0; source < n; ++source)
                if (matrix[source * n + target] != 0) incoming += outgoing[source];
            scores[target] = base_score + damping * incoming;
            outgoing[target] = scores[target] / static_cast<float>(outdegree[target]);
        }
    }
    double weighted = 0.0;
    for (std::size_t node = 0; node < n; ++node) weighted += static_cast<double>(node + 1) * static_cast<double>(scores[node]);
    return static_cast<std::int64_t>(weighted * 100.0 + 0.5);
}
