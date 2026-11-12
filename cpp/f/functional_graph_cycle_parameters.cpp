#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 64;
constexpr std::int64_t encoding_base = 65;

std::int64_t next_node(const std::int64_t* input, std::int64_t node) {
    return input[2 + static_cast<std::size_t>(node)];
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length < 3 || length > static_cast<std::size_t>(max_n + 2)) return -1;
    const auto n = input[0];
    const auto start = input[1];
    if (n < 1 || n > max_n || start < 0 || start >= n || length != static_cast<std::size_t>(n + 2)) return -1;
    for (std::int64_t i = 0; i < n; ++i) {
        const auto successor = input[2 + static_cast<std::size_t>(i)];
        if (successor < 0 || successor >= n) return -1;
    }

    auto tortoise = next_node(input, start);
    auto hare = next_node(input, next_node(input, start));
    while (tortoise != hare) {
        tortoise = next_node(input, tortoise);
        hare = next_node(input, next_node(input, hare));
    }
    std::int64_t mu = 0;
    tortoise = start;
    while (tortoise != hare) {
        tortoise = next_node(input, tortoise);
        hare = next_node(input, hare);
        ++mu;
    }
    std::int64_t lambda = 1;
    hare = next_node(input, tortoise);
    while (hare != tortoise) {
        hare = next_node(input, hare);
        ++lambda;
    }
    return encoding_base * mu + lambda;
}
}

extern "C" std::int64_t functional_graph_cycle_parameters(const std::int64_t* input,
        std::size_t length) noexcept {
    return solve(input, length);
}
