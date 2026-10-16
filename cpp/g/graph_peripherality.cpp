// Bounded weighted directed graph peripherality and farness.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int max_vertices = 8;
constexpr int max_edges = 56;
constexpr std::int64_t infinity = std::numeric_limits<std::int64_t>::max() / 4;
void put_i64(std::uint8_t *output, std::size_t word, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t graph_peripherality(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2) return -1;
    const auto n_value = input[0], edge_value = input[1];
    if (n_value < 1 || n_value > max_vertices || edge_value < 0 || edge_value > max_edges ||
        edge_value > n_value * (n_value - 1) || length != 2 + 3 * static_cast<std::size_t>(edge_value)) return -1;
    const int n = static_cast<int>(n_value), edge_count = static_cast<int>(edge_value);
    std::int64_t distance[max_vertices][max_vertices];
    for (int i = 0; i < n; ++i) for (int j = 0; j < n; ++j) distance[i][j] = i == j ? 0 : infinity;
    for (int edge = 0; edge < edge_count; ++edge) {
        const auto source_value = input[2 + 3 * edge], destination_value = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (source_value < 0 || source_value >= n || destination_value < 0 || destination_value >= n ||
            source_value == destination_value || weight < 1 || weight > 1000000) return -1;
        const int source = static_cast<int>(source_value), destination = static_cast<int>(destination_value);
        if (distance[source][destination] != infinity) return -1;
        distance[source][destination] = weight;
    }
    for (int middle = 0; middle < n; ++middle)
        for (int source = 0; source < n; ++source) {
            if (distance[source][middle] == infinity) continue;
            for (int destination = 0; destination < n; ++destination)
                if (distance[middle][destination] != infinity && distance[source][middle] + distance[middle][destination] < distance[source][destination])
                    distance[source][destination] = distance[source][middle] + distance[middle][destination];
        }
    if (n > 1)
        for (int source = 0; source < n; ++source)
            for (int destination = 0; destination < n; ++destination)
                if (source != destination && distance[source][destination] == infinity) return -1;
    int peripheral = -1, far = -1, peripheral_infinite = 0, far_infinite = 0, any_reachable = 0;
    std::int64_t best_eccentricity = -1, best_farness = -1;
    if (n == 1) { peripheral = far = 0; best_eccentricity = best_farness = 0; }
    else {
        for (int source = 0; source < n; ++source) {
            int found = 0;
            std::int64_t eccentricity = 0, farness = 0;
            for (int destination = 0; destination < n; ++destination) {
                const auto value = distance[source][destination];
                if (destination == source || value == infinity || value == 0) continue;
                found = 1; if (value > eccentricity) eccentricity = value; farness += value;
            }
            if (found) any_reachable = 1;
            const int infinite = !found;
            if (peripheral < 0 || (infinite && !peripheral_infinite) ||
                (infinite == peripheral_infinite && (infinite || eccentricity > best_eccentricity ||
                 (eccentricity == best_eccentricity && source < peripheral)))) {
                peripheral = source; peripheral_infinite = infinite; best_eccentricity = eccentricity;
            }
            if (far < 0 || (infinite && !far_infinite) ||
                (infinite == far_infinite && (infinite || farness > best_farness ||
                 (farness == best_farness && source < far)))) {
                far = source; far_infinite = infinite; best_farness = farness;
            }
        }
        if (!any_reachable) { peripheral = far = -1; best_eccentricity = best_farness = -1; }
        else { if (peripheral_infinite) best_eccentricity = -1; if (far_infinite) best_farness = -1; }
    }
    if (output == nullptr || capacity < 32) return -2;
    put_i64(output, 0, peripheral); put_i64(output, 1, best_eccentricity);
    put_i64(output, 2, far); put_i64(output, 3, best_farness);
    return 32;
}
