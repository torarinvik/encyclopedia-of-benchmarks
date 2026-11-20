module fiduccia_mattheyses_hypergraph_bipartitioning;

const int MAX_VERTICES = 8;
const int MAX_EDGES = 12;
const int MAX_PINS = MAX_VERTICES * MAX_EDGES;
const usz MAX_PARSEABLE_LENGTH = 112;

struct FMState {
    int vertex_count;
    int edge_count;
    int[12] edge_degree;
    int[96] edge_vertices;
}

fn int cut_net_count(FMState* state, int* side) {
    int cut = 0;
    for (int edge = 0; edge < state.edge_count; edge++) {
        int offset = edge * MAX_VERTICES;
        int first_side = side[state.edge_vertices[offset]];
        for (int pin = 1; pin < state.edge_degree[edge]; pin++) {
            if (side[state.edge_vertices[offset + pin]] != first_side) {
                cut++;
                break;
            }
        }
    }
    return cut;
}

fn int move_gain(FMState* state, int* side, int vertex) {
    int gain = 0;
    for (int edge = 0; edge < state.edge_count; edge++) {
        int offset = edge * MAX_VERTICES;
        bool contains_vertex = false;
        int count_a = 0, count_b = 0;
        for (int pin = 0; pin < state.edge_degree[edge]; pin++) {
            int member = state.edge_vertices[offset + pin];
            if (member == vertex) contains_vertex = true;
            if (side[member] == 0) count_a++;
            else count_b++;
        }
        if (!contains_vertex) continue;

        int before_cut = count_a > 0 && count_b > 0 ? 1 : 0;
        if (side[vertex] == 0) { count_a--; count_b++; }
        else { count_b--; count_a++; }
        int after_cut = count_a > 0 && count_b > 0 ? 1 : 0;
        gain += before_cut - after_cut;
    }
    return gain;
}

fn int partition_mask(int* side, int vertex_count) {
    int mask = 0;
    for (int vertex = 0; vertex < vertex_count; vertex++)
        if (side[vertex] == 0) mask |= 1 << vertex;
    return mask;
}

fn long fiduccia_mattheyses_hypergraph_bipartitioning(long* input, usz length)
    @export("fiduccia_mattheyses_hypergraph_bipartitioning") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    long vertex_count_value = input[0], edge_count_value = input[1], initial_mask_value = input[2];
    if (vertex_count_value < 4 || vertex_count_value > MAX_VERTICES || vertex_count_value % 2 != 0 ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES || initial_mask_value < 0 ||
        initial_mask_value >= (long)(1 << (int)vertex_count_value)) return -1;

    int vertex_count = (int)vertex_count_value;
    int edge_count = (int)edge_count_value;
    int initial_a_count = 0;
    for (int vertex = 0; vertex < vertex_count; vertex++)
        if ((initial_mask_value & (long)(1 << vertex)) != 0) initial_a_count++;
    if (initial_a_count != vertex_count / 2) return -1;

    FMState state = {};
    state.vertex_count = vertex_count;
    state.edge_count = edge_count;
    usz cursor = 3;
    for (int edge = 0; edge < edge_count; edge++) {
        if (cursor >= length) return -1;
        long degree_value = input[cursor++];
        if (degree_value < 2 || degree_value > vertex_count || cursor + (usz)degree_value > length) return -1;
        state.edge_degree[edge] = (int)degree_value;
        for (int pin = 0; pin < (int)degree_value; pin++) {
            long member_value = input[cursor++];
            if (member_value < 0 || member_value >= vertex_count ||
                (pin > 0 && member_value <= state.edge_vertices[edge * MAX_VERTICES + pin - 1])) return -1;
            state.edge_vertices[edge * MAX_VERTICES + pin] = (int)member_value;
        }
    }
    if (cursor != length) return -1;

    int[MAX_VERTICES] side;
    for (int vertex = 0; vertex < vertex_count; vertex++)
        side[vertex] = (initial_mask_value & (long)(1 << vertex)) != 0 ? 0 : 1;

    int half = vertex_count / 2;
    while (true) {
        bool[MAX_VERTICES] locked;
        for (int vertex = 0; vertex < vertex_count; vertex++) locked[vertex] = false;
        int pass_start_mask = partition_mask(&side[0], vertex_count);
        int pass_start_cut = cut_net_count(&state, &side[0]);
        int best_mask = pass_start_mask;
        int best_cut = pass_start_cut;
        int size_a = 0;
        for (int vertex = 0; vertex < vertex_count; vertex++)
            if (side[vertex] == 0) size_a++;

        while (true) {
            int[2 * MAX_EDGES + 1] buckets_a, buckets_b;
            for (int bucket = 0; bucket < 2 * MAX_EDGES + 1; bucket++) {
                buckets_a[bucket] = 0;
                buckets_b[bucket] = 0;
            }
            for (int vertex = 0; vertex < vertex_count; vertex++) {
                if (locked[vertex]) continue;
                int gain = move_gain(&state, &side[0], vertex);
                int bucket_index = gain + edge_count;
                if (side[vertex] == 0) buckets_a[bucket_index] |= 1 << vertex;
                else buckets_b[bucket_index] |= 1 << vertex;
            }

            int chosen = -1;
            int chosen_gain = -edge_count - 1;
            int chosen_imbalance = MAX_VERTICES + 1;
            for (int from_side = 0; from_side <= 1; from_side++) {
                int resulting_a_size = size_a + (from_side == 0 ? -1 : 1);
                if (resulting_a_size < half - 1 || resulting_a_size > half + 1) continue;
                int side_candidate = -1;
                int side_gain = -edge_count - 1;
                for (int gain = edge_count; gain >= -edge_count; gain--) {
                    int members = from_side == 0 ? buckets_a[gain + edge_count] : buckets_b[gain + edge_count];
                    if (members == 0) continue;
                    for (int vertex = 0; vertex < vertex_count; vertex++) {
                        if ((members & (1 << vertex)) != 0) {
                            side_candidate = vertex;
                            side_gain = gain;
                            break;
                        }
                    }
                    if (side_candidate >= 0) break;
                }
                if (side_candidate < 0) continue;
                int imbalance = resulting_a_size * 2 - vertex_count;
                int absolute_imbalance = imbalance < 0 ? -imbalance : imbalance;
                if (chosen < 0 || side_gain > chosen_gain ||
                    (side_gain == chosen_gain && absolute_imbalance < chosen_imbalance) ||
                    (side_gain == chosen_gain && absolute_imbalance == chosen_imbalance && side_candidate < chosen)) {
                    chosen = side_candidate;
                    chosen_gain = side_gain;
                    chosen_imbalance = absolute_imbalance;
                }
            }
            if (chosen < 0) break;

            int from_side = side[chosen];
            side[chosen] = 1 - from_side;
            locked[chosen] = true;
            size_a += from_side == 0 ? -1 : 1;

            int current_cut = cut_net_count(&state, &side[0]);
            if (current_cut < best_cut) {
                best_cut = current_cut;
                best_mask = partition_mask(&side[0], vertex_count);
            }
        }

        if (best_cut >= pass_start_cut) break;
        for (int vertex = 0; vertex < vertex_count; vertex++)
            side[vertex] = (best_mask & (1 << vertex)) != 0 ? 0 : 1;
    }

    int final_cut = cut_net_count(&state, &side[0]);
    int final_mask = partition_mask(&side[0], vertex_count);
    return ((long)final_cut << 8) | (long)final_mask;
}
