#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 16;
constexpr std::size_t max_edges = 64;
constexpr std::int64_t score_scale = 1'000'000;
}

extern "C" std::int64_t hits_fixed_point(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 132) return -1;

    const auto vertex_count_value = input[0];
    const auto edge_count_value = input[1];
    const auto iteration_count_value = input[2];
    if (vertex_count_value < 1 || vertex_count_value > static_cast<std::int64_t>(max_vertices) ||
        edge_count_value < 0 || edge_count_value > static_cast<std::int64_t>(max_edges) ||
        iteration_count_value < 0 || iteration_count_value > 32) return -1;

    const auto vertex_count = static_cast<std::size_t>(vertex_count_value);
    const auto edge_count = static_cast<std::size_t>(edge_count_value);
    const auto iteration_count = static_cast<std::size_t>(iteration_count_value);
    if (length != 3 + 2 * edge_count) return -1;

    std::array<std::size_t, max_edges> sources{};
    std::array<std::size_t, max_edges> targets{};
    std::array<std::array<bool, max_vertices>, max_vertices> seen{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto source_value = input[3 + 2 * edge];
        const auto target_value = input[4 + 2 * edge];
        if (source_value < 0 || source_value >= vertex_count_value ||
            target_value < 0 || target_value >= vertex_count_value ||
            source_value == target_value) return -1;
        const auto source = static_cast<std::size_t>(source_value);
        const auto target = static_cast<std::size_t>(target_value);
        if (seen[source][target]) return -1;
        seen[source][target] = true;
        sources[edge] = source;
        targets[edge] = target;
    }

    std::array<std::int64_t, max_vertices> hubs{};
    std::array<std::int64_t, max_vertices> authorities{};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) hubs[vertex] = score_scale;

    for (std::size_t iteration = 0; iteration < iteration_count; ++iteration) {
        std::array<std::int64_t, max_vertices> raw{};
        for (std::size_t edge = 0; edge < edge_count; ++edge)
            raw[targets[edge]] += hubs[sources[edge]];
        std::int64_t total = 0;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) total += raw[vertex];
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
            authorities[vertex] = total == 0 ? 0 : raw[vertex] * score_scale / total;

        raw.fill(0);
        for (std::size_t edge = 0; edge < edge_count; ++edge)
            raw[sources[edge]] += authorities[targets[edge]];
        total = 0;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) total += raw[vertex];
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
            hubs[vertex] = total == 0 ? 0 : raw[vertex] * score_scale / total;
    }

    std::int64_t result = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        result += static_cast<std::int64_t>(vertex + 1) *
                  (authorities[vertex] + INT64_C(65537) * hubs[vertex]);
    return result;
}
