#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 8;
constexpr int kMaxEdges = 12;
constexpr int kMaxPins = kMaxVertices * kMaxEdges;
constexpr std::size_t kMaxParseableLength = 112;

struct FMState {
    int vertex_count = 0;
    int edge_count = 0;
    std::array<int, kMaxEdges> edge_degree{};
    std::array<int, kMaxPins> edge_vertices{};
};

int cut_net_count(const FMState& state, const std::array<int, kMaxVertices>& side) noexcept {
    int cut = 0;
    for (int edge = 0; edge < state.edge_count; ++edge) {
        const int offset = edge * kMaxVertices;
        const int first_side = side[state.edge_vertices[offset]];
        for (int pin = 1; pin < state.edge_degree[edge]; ++pin) {
            if (side[state.edge_vertices[offset + pin]] != first_side) {
                ++cut;
                break;
            }
        }
    }
    return cut;
}

int move_gain(const FMState& state, const std::array<int, kMaxVertices>& side,
              int vertex) noexcept {
    int gain = 0;
    for (int edge = 0; edge < state.edge_count; ++edge) {
        const int offset = edge * kMaxVertices;
        bool contains_vertex = false;
        int count_a = 0;
        int count_b = 0;
        for (int pin = 0; pin < state.edge_degree[edge]; ++pin) {
            const int member = state.edge_vertices[offset + pin];
            if (member == vertex) contains_vertex = true;
            if (side[member] == 0) ++count_a;
            else ++count_b;
        }
        if (!contains_vertex) continue;

        const int before_cut = count_a > 0 && count_b > 0;
        if (side[vertex] == 0) {
            --count_a;
            ++count_b;
        } else {
            --count_b;
            ++count_a;
        }
        const int after_cut = count_a > 0 && count_b > 0;
        gain += before_cut - after_cut;
    }
    return gain;
}

int partition_mask(const std::array<int, kMaxVertices>& side, int vertex_count) noexcept {
    int mask = 0;
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        if (side[vertex] == 0) mask |= 1 << vertex;
    return mask;
}
}

extern "C" std::int64_t fiduccia_mattheyses_hypergraph_bipartitioning(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > kMaxParseableLength) return -1;
    const auto vertex_count_value = input[0];
    const auto edge_count_value = input[1];
    const auto initial_mask_value = input[2];
    if (vertex_count_value < 4 || vertex_count_value > kMaxVertices ||
        (vertex_count_value & 1) != 0 || edge_count_value < 0 || edge_count_value > kMaxEdges ||
        initial_mask_value < 0 || initial_mask_value >= (std::int64_t{1} << vertex_count_value))
        return -1;

    const int vertex_count = static_cast<int>(vertex_count_value);
    const int edge_count = static_cast<int>(edge_count_value);
    int initial_a_count = 0;
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        if ((initial_mask_value & (std::int64_t{1} << vertex)) != 0) ++initial_a_count;
    if (initial_a_count != vertex_count / 2) return -1;

    FMState state{};
    state.vertex_count = vertex_count;
    state.edge_count = edge_count;
    std::size_t cursor = 3;
    for (int edge = 0; edge < edge_count; ++edge) {
        if (cursor >= length) return -1;
        const auto degree_value = input[cursor++];
        if (degree_value < 2 || degree_value > vertex_count ||
            cursor + static_cast<std::size_t>(degree_value) > length) return -1;
        state.edge_degree[edge] = static_cast<int>(degree_value);
        for (int pin = 0; pin < static_cast<int>(degree_value); ++pin) {
            const auto member_value = input[cursor++];
            if (member_value < 0 || member_value >= vertex_count ||
                (pin > 0 && member_value <=
                                state.edge_vertices[edge * kMaxVertices + pin - 1])) return -1;
            state.edge_vertices[edge * kMaxVertices + pin] = static_cast<int>(member_value);
        }
    }
    if (cursor != length) return -1;

    std::array<int, kMaxVertices> side{};
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        side[vertex] = (initial_mask_value & (std::int64_t{1} << vertex)) != 0 ? 0 : 1;

    const int half = vertex_count / 2;
    for (;;) {
        std::array<bool, kMaxVertices> locked{};
        const int pass_start_mask = partition_mask(side, vertex_count);
        const int pass_start_cut = cut_net_count(state, side);
        int best_mask = pass_start_mask;
        int best_cut = pass_start_cut;
        int size_a = 0;
        for (int vertex = 0; vertex < vertex_count; ++vertex)
            if (side[vertex] == 0) ++size_a;

        for (;;) {
            std::array<std::array<int, 2 * kMaxEdges + 1>, 2> buckets{};
            for (int vertex = 0; vertex < vertex_count; ++vertex) {
                if (locked[vertex]) continue;
                const int gain = move_gain(state, side, vertex);
                buckets[side[vertex]][gain + edge_count] |= 1 << vertex;
            }

            int chosen = -1;
            int chosen_gain = -edge_count - 1;
            int chosen_imbalance = kMaxVertices + 1;
            for (int from_side = 0; from_side <= 1; ++from_side) {
                const int resulting_a_size = size_a + (from_side == 0 ? -1 : 1);
                if (resulting_a_size < half - 1 || resulting_a_size > half + 1) continue;
                int side_candidate = -1;
                int side_gain = -edge_count - 1;
                for (int gain = edge_count; gain >= -edge_count; --gain) {
                    const int members = buckets[from_side][gain + edge_count];
                    if (members == 0) continue;
                    for (int vertex = 0; vertex < vertex_count; ++vertex) {
                        if ((members & (1 << vertex)) != 0) {
                            side_candidate = vertex;
                            side_gain = gain;
                            break;
                        }
                    }
                    if (side_candidate >= 0) break;
                }
                if (side_candidate < 0) continue;

                const int imbalance = resulting_a_size * 2 - vertex_count;
                const int absolute_imbalance = imbalance < 0 ? -imbalance : imbalance;
                if (chosen < 0 || side_gain > chosen_gain ||
                    (side_gain == chosen_gain && absolute_imbalance < chosen_imbalance) ||
                    (side_gain == chosen_gain && absolute_imbalance == chosen_imbalance &&
                     side_candidate < chosen)) {
                    chosen = side_candidate;
                    chosen_gain = side_gain;
                    chosen_imbalance = absolute_imbalance;
                }
            }
            if (chosen < 0) break;

            const int from_side = side[chosen];
            side[chosen] = 1 - from_side;
            locked[chosen] = true;
            size_a += from_side == 0 ? -1 : 1;

            const int current_cut = cut_net_count(state, side);
            if (current_cut < best_cut) {
                best_cut = current_cut;
                best_mask = partition_mask(side, vertex_count);
            }
        }

        if (best_cut >= pass_start_cut) break;
        for (int vertex = 0; vertex < vertex_count; ++vertex)
            side[vertex] = (best_mask & (1 << vertex)) != 0 ? 0 : 1;
    }

    const int final_cut = cut_net_count(state, side);
    const int final_mask = partition_mask(side, vertex_count);
    return (static_cast<std::int64_t>(final_cut) << 8) | final_mask;
}
