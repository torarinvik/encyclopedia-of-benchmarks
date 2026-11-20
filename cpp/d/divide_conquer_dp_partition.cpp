#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 64, MaxGroups = 8, MaxInput = 66, StackCapacity = 136;
constexpr std::int64_t Inf = INT64_MAX / 4;
struct Task { std::size_t left, right, low, high; };

void compute_row(const std::array<std::int64_t, MaxN + 1>& previous,
                std::array<std::int64_t, MaxN + 1>& current,
                const std::array<std::int64_t, MaxN + 1>& prefix,
                std::size_t n, std::size_t group) {
    std::array<Task, StackCapacity> stack{};
    std::size_t top = 0;
    stack[top++] = {group, n, group - 1, n - 1};
    while (top != 0) {
        const auto task = stack[--top];
        if (task.left > task.right) continue;
        const auto middle = task.left + (task.right - task.left) / 2;
        const auto upper = std::min(task.high, middle - 1);
        auto best = Inf;
        auto best_split = task.low;
        for (auto split = task.low; split <= upper; ++split) {
            if (previous[split] == Inf) continue;
            const auto segment = prefix[middle] - prefix[split];
            const auto candidate = previous[split] + segment * segment;
            if (candidate < best) { best = candidate; best_split = split; }
        }
        current[middle] = best;
        if (middle < task.right) stack[top++] = {middle + 1, task.right, best_split, task.high};
        if (task.left < middle) stack[top++] = {task.left, middle - 1, task.low, best_split};
    }
}
}

extern "C" std::int64_t divide_conquer_dp_partition(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 3 || length > MaxInput) return -1;
    const auto n_value = values[0], groups_value = values[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MaxN) || groups_value < 1 ||
        groups_value > static_cast<std::int64_t>(MaxGroups) || groups_value > n_value ||
        length != static_cast<std::size_t>(n_value) + 2) return -1;
    const auto n = static_cast<std::size_t>(n_value), groups = static_cast<std::size_t>(groups_value);
    std::array<std::int64_t, MaxN + 1> prefix{}, first{}, second{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = values[i + 2];
        if (value < 0 || value > 1000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    first.fill(Inf); first[0] = 0;
    auto *previous = &first, *current = &second;
    for (std::size_t group = 1; group <= groups; ++group) {
        current->fill(Inf);
        compute_row(*previous, *current, prefix, n, group);
        std::swap(previous, current);
    }
    return (*previous)[n];
}
