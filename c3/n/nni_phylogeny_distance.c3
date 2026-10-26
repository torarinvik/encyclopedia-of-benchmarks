module nni_phylogeny_distance;

const usz MAX_LEAVES = 7;
const usz MAX_EDGES = 11;
const usz MAX_INPUT = 23;
const usz MAX_STATES = 945;
const usz MAX_DEGREE = 8;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[byte] = (char)(bits & 255); bits >>= 8; }
}

fn usz bit_count(ushort value, usz n) {
    usz count = 0;
    for (usz bit = 0; bit < n; bit += 1) count += (usz)((value >> bit) & 1);
    return count;
}

fn bool valid_tree(long* input, usz offset, usz n, usz edges) {
    ushort[MAX_EDGES] splits = zeroed;
    ushort[MAX_EDGES] internal = zeroed;
    usz internal_count = 0;
    ushort universe = (ushort)((1 << n) - 1);
    for (usz i = 0; i < edges; i += 1) {
        long raw = input[offset + i];
        if (raw <= 0 || (ulong)raw >= universe || (raw & 1) != 0) return false;
        splits[i] = (ushort)raw;
        for (usz earlier = 0; earlier < i; earlier += 1) if (splits[earlier] == splits[i]) return false;
        usz count = bit_count(splits[i], n);
        if (count == 1 || count == n - 1) {
            if (count == n - 1 && splits[i] != (universe ^ 1)) return false;
        } else if (count >= 2 && count <= n - 2) {
            internal[internal_count] = splits[i];
            internal_count += 1;
        } else return false;
    }
    if (internal_count != n - 3) return false;
    for (usz leaf = 1; leaf < n; leaf += 1) {
        ushort pendant = (ushort)(1 << leaf);
        usz found = 0;
        for (usz edge = 0; edge < edges; edge += 1) if (splits[edge] == pendant) found += 1;
        if (found != 1) return false;
    }
    usz root_pendant = 0;
    for (usz edge = 0; edge < edges; edge += 1) if (splits[edge] == (universe ^ 1)) root_pendant += 1;
    if (root_pendant != 1) return false;
    for (usz i = 0; i < internal_count; i += 1) {
        for (usz j = i + 1; j < internal_count; j += 1) {
            ushort common = internal[i] & internal[j];
            if (common != 0 && common != internal[i] && common != internal[j]) return false;
        }
    }
    return true;
}

fn void sort_state(ushort* state, usz count) {
    for (usz i = 1; i < count; i += 1) {
        ushort value = state[i];
        usz j = i;
        while (j > 0 && state[j - 1] > value) { state[j] = state[j - 1]; j -= 1; }
        state[j] = value;
    }
}

fn bool same_state(ushort* left, ushort* right, usz edges) {
    for (usz i = 0; i < edges; i += 1) if (left[i] != right[i]) return false;
    return true;
}

fn ushort* enumerate_states(usz leaves, ushort* a, ushort* b, usz* state_count) {
    ushort* current = a;
    ushort* next = b;
    current[0] = 2; current[1] = 4; current[2] = 6;
    *state_count = 1;
    usz old_edges = 3;
    for (usz size = 4; size <= leaves; size += 1) {
        usz new_edges = old_edges + 2;
        ushort new_bit = (ushort)(1 << (size - 1));
        usz next_count = 0;
        for (usz state_index = 0; state_index < *state_count; state_index += 1) {
            ushort* old = current + state_index * MAX_EDGES;
            for (usz selected_index = 0; selected_index < old_edges; selected_index += 1) {
                ushort selected = old[selected_index];
                ushort[MAX_EDGES] candidate = zeroed;
                usz candidate_count = 0;
                for (usz edge = 0; edge < old_edges; edge += 1) {
                    ushort split = old[edge];
                    if (split == selected) {
                        candidate[candidate_count] = split; candidate_count += 1;
                        candidate[candidate_count] = split | new_bit; candidate_count += 1;
                    } else if ((selected & split) == selected) {
                        candidate[candidate_count] = split | new_bit; candidate_count += 1;
                    } else {
                        candidate[candidate_count] = split; candidate_count += 1;
                    }
                }
                candidate[candidate_count] = new_bit; candidate_count += 1;
                sort_state(&candidate[0], candidate_count);
                usz found = 0;
                while (found < next_count && !same_state(next + found * MAX_EDGES, &candidate[0], new_edges)) found += 1;
                if (found == next_count) {
                    if (next_count >= MAX_STATES) return null;
                    for (usz edge = 0; edge < new_edges; edge += 1) next[next_count * MAX_EDGES + edge] = candidate[edge];
                    next_count += 1;
                }
            }
        }
        ushort* swap = current; current = next; next = swap;
        *state_count = next_count;
        old_edges = new_edges;
    }
    return current;
}

long nni_phylogeny_distance(long* input, usz length, char* output, usz capacity) @export("nni_phylogeny_distance") {
    if (input == null || length < 7 || length > MAX_INPUT) return -1;
    long leaf_value = input[0];
    if (leaf_value < 3 || leaf_value > (long)MAX_LEAVES) return -1;
    usz leaves = (usz)leaf_value;
    usz edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges || !valid_tree(input, 1, leaves, edges)
        || !valid_tree(input, 1 + edges, leaves, edges)) return -1;

    ushort[MAX_STATES * MAX_EDGES] states_a = zeroed;
    ushort[MAX_STATES * MAX_EDGES] states_b = zeroed;
    usz state_count = 0;
    ushort* states = enumerate_states(leaves, &states_a[0], &states_b[0], &state_count);
    if (states == null) return -1;
    ushort[MAX_EDGES] start = zeroed, goal = zeroed;
    for (usz i = 0; i < edges; i += 1) {
        start[i] = (ushort)input[1 + i];
        goal[i] = (ushort)input[1 + edges + i];
    }
    sort_state(&start[0], edges); sort_state(&goal[0], edges);
    usz start_index = state_count, goal_index = state_count;
    for (usz i = 0; i < state_count; i += 1) {
        if (same_state(states + i * MAX_EDGES, &start[0], edges)) start_index = i;
        if (same_state(states + i * MAX_EDGES, &goal[0], edges)) goal_index = i;
    }
    if (start_index == state_count || goal_index == state_count) return -1;

    ushort[MAX_STATES * MAX_DEGREE] neighbors = zeroed;
    ubyte[MAX_STATES] degree = zeroed;
    for (usz left = 0; left < state_count; left += 1) {
        for (usz right = left + 1; right < state_count; right += 1) {
            usz common = 0;
            for (usz i = 0; i < edges; i += 1) {
                usz left_size = bit_count(states[left * MAX_EDGES + i], leaves);
                if (left_size < 2 || left_size > leaves - 2) continue;
                for (usz j = 0; j < edges; j += 1) {
                    usz right_size = bit_count(states[right * MAX_EDGES + j], leaves);
                    if (right_size >= 2 && right_size <= leaves - 2 && states[left * MAX_EDGES + i] == states[right * MAX_EDGES + j]) { common += 1; break; }
                }
            }
            if (common + leaves == edges - 1) {
                if (degree[left] >= MAX_DEGREE || degree[right] >= MAX_DEGREE) return -1;
                neighbors[left * MAX_DEGREE + degree[left]] = (ushort)right; degree[left] += 1;
                neighbors[right * MAX_DEGREE + degree[right]] = (ushort)left; degree[right] += 1;
            }
        }
    }
    short[MAX_STATES] distance = zeroed;
    ushort[MAX_STATES] queue = zeroed;
    for (usz i = 0; i < state_count; i += 1) distance[i] = -1;
    usz head = 0, tail = 0;
    distance[start_index] = 0; queue[tail] = (ushort)start_index; tail += 1;
    while (head < tail) {
        usz current = queue[head]; head += 1;
        if (current == goal_index) break;
        for (usz i = 0; i < degree[current]; i += 1) {
            usz next = neighbors[current * MAX_DEGREE + i];
            if (distance[next] < 0) {
                distance[next] = (short)(distance[current] + 1);
                queue[tail] = (ushort)next; tail += 1;
            }
        }
    }
    if (distance[goal_index] < 0) return -1;
    if (output == null || capacity < 8) return -2;
    char[8] staged = zeroed;
    store_i64_le(&staged[0], distance[goal_index]);
    for (usz byte = 0; byte < 8; byte += 1) output[byte] = staged[byte];
    return 8;
}
