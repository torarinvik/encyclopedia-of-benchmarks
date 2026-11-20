#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 12
#define MAX_PINS (MAX_VERTICES * MAX_EDGES)
#define MAX_PARSEABLE_LENGTH 112

typedef struct {
    int vertex_count;
    int edge_count;
    int edge_degree[MAX_EDGES];
    int edge_vertices[MAX_PINS];
} FMState;

static int cut_net_count(const FMState *state, const int *side) {
    int cut = 0;
    for (int edge = 0; edge < state->edge_count; ++edge) {
        const int offset = edge * MAX_VERTICES;
        const int first_side = side[state->edge_vertices[offset]];
        for (int pin = 1; pin < state->edge_degree[edge]; ++pin) {
            if (side[state->edge_vertices[offset + pin]] != first_side) {
                ++cut;
                break;
            }
        }
    }
    return cut;
}

static int move_gain(const FMState *state, const int *side, int vertex) {
    int gain = 0;
    for (int edge = 0; edge < state->edge_count; ++edge) {
        const int offset = edge * MAX_VERTICES;
        int contains_vertex = 0;
        int count_a = 0;
        int count_b = 0;
        for (int pin = 0; pin < state->edge_degree[edge]; ++pin) {
            const int member = state->edge_vertices[offset + pin];
            if (member == vertex) contains_vertex = 1;
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

static int partition_mask(const int *side, int vertex_count) {
    int mask = 0;
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        if (side[vertex] == 0) mask |= 1 << vertex;
    return mask;
}

int64_t fiduccia_mattheyses_hypergraph_bipartitioning(const int64_t *input,
                                                       size_t length) {
    if (input == NULL || length < 3u || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t vertex_count_value = input[0];
    const int64_t edge_count_value = input[1];
    const int64_t initial_mask_value = input[2];
    if (vertex_count_value < 4 || vertex_count_value > MAX_VERTICES ||
        (vertex_count_value & 1) != 0 || edge_count_value < 0 || edge_count_value > MAX_EDGES ||
        initial_mask_value < 0 ||
        initial_mask_value >= (INT64_C(1) << vertex_count_value)) return -1;

    const int vertex_count = (int)vertex_count_value;
    const int edge_count = (int)edge_count_value;
    int initial_a_count = 0;
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        if ((initial_mask_value & (INT64_C(1) << vertex)) != 0) ++initial_a_count;
    if (initial_a_count != vertex_count / 2) return -1;

    FMState state = {0};
    state.vertex_count = vertex_count;
    state.edge_count = edge_count;
    size_t cursor = 3u;
    for (int edge = 0; edge < edge_count; ++edge) {
        if (cursor >= length) return -1;
        const int64_t degree_value = input[cursor++];
        if (degree_value < 2 || degree_value > vertex_count ||
            cursor + (size_t)degree_value > length) return -1;
        state.edge_degree[edge] = (int)degree_value;
        for (int pin = 0; pin < (int)degree_value; ++pin) {
            const int64_t vertex_value = input[cursor++];
            if (vertex_value < 0 || vertex_value >= vertex_count ||
                (pin > 0 && vertex_value <= state.edge_vertices[edge * MAX_VERTICES + pin - 1]))
                return -1;
            state.edge_vertices[edge * MAX_VERTICES + pin] = (int)vertex_value;
        }
    }
    if (cursor != length) return -1;

    int side[MAX_VERTICES] = {0};
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        side[vertex] = (initial_mask_value & (INT64_C(1) << vertex)) != 0 ? 0 : 1;

    const int half = vertex_count / 2;
    for (;;) {
        unsigned char locked[MAX_VERTICES] = {0};
        const int pass_start_mask = partition_mask(side, vertex_count);
        const int pass_start_cut = cut_net_count(&state, side);
        int best_mask = pass_start_mask;
        int best_cut = pass_start_cut;
        int size_a = 0;
        for (int vertex = 0; vertex < vertex_count; ++vertex)
            if (side[vertex] == 0) ++size_a;

        for (;;) {
            unsigned short buckets[2][2 * MAX_EDGES + 1] = {{0}};
            for (int vertex = 0; vertex < vertex_count; ++vertex) {
                if (locked[vertex]) continue;
                const int gain = move_gain(&state, side, vertex);
                buckets[side[vertex]][gain + edge_count] |= (unsigned short)(1u << vertex);
            }

            int chosen = -1;
            int chosen_gain = -edge_count - 1;
            int chosen_imbalance = MAX_VERTICES + 1;
            for (int from_side = 0; from_side <= 1; ++from_side) {
                const int resulting_a_size = size_a + (from_side == 0 ? -1 : 1);
                if (resulting_a_size < half - 1 || resulting_a_size > half + 1) continue;
                int side_candidate = -1;
                int side_gain = -edge_count - 1;
                for (int gain = edge_count; gain >= -edge_count; --gain) {
                    const unsigned short members = buckets[from_side][gain + edge_count];
                    if (members == 0) continue;
                    for (int vertex = 0; vertex < vertex_count; ++vertex) {
                        if ((members & (unsigned short)(1u << vertex)) != 0) {
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
            locked[chosen] = 1;
            size_a += from_side == 0 ? -1 : 1;

            const int current_cut = cut_net_count(&state, side);
            if (current_cut < best_cut) {
                best_cut = current_cut;
                best_mask = partition_mask(side, vertex_count);
            }
        }

        if (best_cut >= pass_start_cut) break;
        for (int vertex = 0; vertex < vertex_count; ++vertex)
            side[vertex] = (best_mask & (1 << vertex)) != 0 ? 0 : 1;
    }

    const int final_cut = cut_net_count(&state, side);
    const int final_mask = partition_mask(side, vertex_count);
    return ((int64_t)final_cut << 8) | final_mask;
}
