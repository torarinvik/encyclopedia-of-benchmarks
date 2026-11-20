/* Bounded synchronous-round push-relabel; rounds are simulated sequentially. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 8;
constexpr int max_arcs = 24;
constexpr std::size_t max_input_length = 77;
constexpr std::int64_t max_capacity = 15;
}

extern "C" std::int64_t synchronous_round_push_relabel(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const auto raw_n = input[0], raw_m = input[1], raw_source = input[2], raw_sink = input[3];
    if (raw_n < 2 || raw_n > max_vertices || raw_m < 0 || raw_m > max_arcs ||
        raw_source < 0 || raw_source >= raw_n || raw_sink < 0 || raw_sink >= raw_n ||
        raw_source == raw_sink || length != 4 + 3 * static_cast<std::size_t>(raw_m)) return -1;
    const int n = static_cast<int>(raw_n), m = static_cast<int>(raw_m);
    const int source = static_cast<int>(raw_source), sink = static_cast<int>(raw_sink);
    std::array<std::array<std::int64_t, max_vertices>, max_vertices> capacity{};
    for (int i = 0; i < m; ++i) {
        const auto offset = 4 + 3 * static_cast<std::size_t>(i);
        const auto u = input[offset], v = input[offset + 1], c = input[offset + 2];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || c < 0 || c > max_capacity)
            return -1;
        capacity[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] += c;
    }

    auto residual = capacity;
    std::array<std::int64_t, max_vertices> excess{};
    std::array<int, max_vertices> height{};
    height[static_cast<std::size_t>(source)] = n;
    for (int v = 0; v < n; ++v) {
        if (v == source) continue;
        const auto amount = residual[static_cast<std::size_t>(source)][static_cast<std::size_t>(v)];
        if (amount != 0) {
            residual[static_cast<std::size_t>(source)][static_cast<std::size_t>(v)] = 0;
            residual[static_cast<std::size_t>(v)][static_cast<std::size_t>(source)] += amount;
            excess[static_cast<std::size_t>(source)] -= amount;
            excess[static_cast<std::size_t>(v)] += amount;
        }
    }

    for (;;) {
        std::array<int, max_vertices> active{};
        int active_count = 0;
        for (int v = 0; v < n; ++v)
            if (v != source && v != sink && excess[static_cast<std::size_t>(v)] > 0 &&
                height[static_cast<std::size_t>(v)] < n) active[active_count++] = v;
        if (active_count == 0) return excess[static_cast<std::size_t>(sink)];

        std::array<std::int64_t, max_vertices> change{};
        for (int ai = 0; ai < active_count; ++ai) {
            const int u = active[ai];
            auto remaining = excess[static_cast<std::size_t>(u)];
            for (int v = 0; v < n && remaining > 0; ++v) {
                auto& forward = residual[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)];
                if (forward > 0 && height[static_cast<std::size_t>(u)] ==
                    height[static_cast<std::size_t>(v)] + 1) {
                    const auto amount = remaining < forward ? remaining : forward;
                    forward -= amount;
                    residual[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] += amount;
                    change[static_cast<std::size_t>(u)] -= amount;
                    change[static_cast<std::size_t>(v)] += amount;
                    remaining -= amount;
                }
            }
        }

        auto next_excess = excess;
        auto next_height = height;
        for (int v = 0; v < n; ++v)
            next_excess[static_cast<std::size_t>(v)] += change[static_cast<std::size_t>(v)];
        for (int ai = 0; ai < active_count; ++ai) {
            const int u = active[ai];
            if (next_excess[static_cast<std::size_t>(u)] <= 0) continue;
            int minimum = 2 * max_vertices + 1;
            for (int v = 0; v < n; ++v)
                if (residual[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] > 0 &&
                    height[static_cast<std::size_t>(v)] < minimum)
                    minimum = height[static_cast<std::size_t>(v)];
            next_height[static_cast<std::size_t>(u)] = minimum == 2 * max_vertices + 1
                ? n + 1 : minimum + 1;
        }
        excess = next_excess;
        height = next_height;
    }
}
