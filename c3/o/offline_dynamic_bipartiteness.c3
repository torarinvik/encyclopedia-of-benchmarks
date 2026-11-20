module offline_dynamic_bipartiteness;

const int MAX_VERTICES = 16;
const int MAX_EVENTS = 64;
const usz MAX_INPUT_VALUES = 2 + 4 * MAX_EVENTS + 1;
const int TREE_NODES = 4 * MAX_EVENTS + 8;

fn void add_interval(usz node, usz left, usz right, usz query_left,
    usz query_right, usz edge_id, usz* bucket_count,
    usz[MAX_EVENTS]* buckets) {
    if (query_left <= left && right <= query_right) {
        buckets[node][bucket_count[node]] = edge_id;
        bucket_count[node] += 1;
        return;
    }
    usz middle = left + (right - left) / 2;
    if (query_left < middle)
        add_interval(2 * node, left, middle, query_left, query_right,
                     edge_id, bucket_count, buckets);
    if (query_right > middle)
        add_interval(2 * node + 1, middle, right, query_left, query_right,
                     edge_id, bucket_count, buckets);
}

fn void constrain_opposite(usz left, usz right, usz* parent,
    usz* set_size, usz* xor_parent, usz* history_kind,
    usz* history_child, usz* history_root, usz* history_size,
    usz* history_xor, usz* history_count, usz* contradictions) {
    usz root_left = left; usz root_right = right;
    usz parity_left = 0; usz parity_right = 0;
    while (parent[root_left] != root_left) {
        parity_left ^= xor_parent[root_left];
        root_left = parent[root_left];
    }
    while (parent[root_right] != root_right) {
        parity_right ^= xor_parent[root_right];
        root_right = parent[root_right];
    }
    if (root_left == root_right) {
        if ((parity_left ^ parity_right) != 1) {
            history_kind[*history_count] = 1;
            *history_count += 1;
            *contradictions += 1;
        }
        return;
    }
    if (set_size[root_left] > set_size[root_right]) {
        usz temporary = root_left; root_left = root_right; root_right = temporary;
    }
    history_kind[*history_count] = 0;
    history_child[*history_count] = root_left;
    history_root[*history_count] = root_right;
    history_size[*history_count] = set_size[root_right];
    history_xor[*history_count] = xor_parent[root_left];
    *history_count += 1;
    parent[root_left] = root_right;
    xor_parent[root_left] = parity_left ^ parity_right ^ 1;
    set_size[root_right] += set_size[root_left];
}

fn void rollback_to(usz checkpoint, usz* parent, usz* set_size,
    usz* xor_parent, usz* history_kind, usz* history_child,
    usz* history_root, usz* history_size, usz* history_xor,
    usz* history_count, usz* contradictions) {
    while (*history_count > checkpoint) {
        *history_count -= 1;
        usz entry = *history_count;
        if (history_kind[entry] == 1) {
            *contradictions -= 1;
        } else {
            usz child = history_child[entry]; usz root = history_root[entry];
            parent[child] = child;
            xor_parent[child] = history_xor[entry];
            set_size[root] = history_size[entry];
        }
    }
}

fn void solve_time_tree(usz node, usz left, usz right,
    long* operation, long* first, long* second, long* edge_left,
    long* edge_right, usz* bucket_count, usz[MAX_EVENTS]* buckets,
    usz* parent, usz* set_size, usz* xor_parent, usz* history_kind,
    usz* history_child, usz* history_root, usz* history_size,
    usz* history_xor, usz* history_count, usz* contradictions, long* answer) {
    usz checkpoint = *history_count;
    for (usz entry = 0; entry < bucket_count[node]; entry += 1) {
        usz edge_id = buckets[node][entry];
        constrain_opposite((usz)edge_left[edge_id], (usz)edge_right[edge_id],
            parent, set_size, xor_parent, history_kind, history_child,
            history_root, history_size, history_xor, history_count, contradictions);
    }
    if (right - left == 1) {
        if (operation[left] == 2) answer[left] = *contradictions == 0 ? 1 : 0;
    } else {
        usz middle = left + (right - left) / 2;
        solve_time_tree(2 * node, left, middle, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            xor_parent, history_kind, history_child, history_root, history_size,
            history_xor, history_count, contradictions, answer);
        solve_time_tree(2 * node + 1, middle, right, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            xor_parent, history_kind, history_child, history_root, history_size,
            history_xor, history_count, contradictions, answer);
    }
    rollback_to(checkpoint, parent, set_size, xor_parent, history_kind,
        history_child, history_root, history_size, history_xor,
        history_count, contradictions);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long offline_dynamic_bipartiteness(long* input, usz length, char* output,
    usz capacity) @export("offline_dynamic_bipartiteness") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EVENTS) return -1;
    usz vertex_count = (usz)input[0]; usz event_count = (usz)input[1];
    if (length != 2 + 4 * event_count) return -1;

    long[MAX_EVENTS] operation, first, second, edge_left, edge_right;
    usz[MAX_EVENTS] start_time;
    bool[MAX_EVENTS] used_id = zeroed; bool[MAX_EVENTS] active = zeroed;
    usz query_count = 0;
    for (usz time = 0; time < event_count; time += 1) {
        usz offset = 2 + 4 * time;
        operation[time] = input[offset]; first[time] = input[offset + 1];
        second[time] = input[offset + 2]; long third = input[offset + 3];
        if (operation[time] == 0) {
            long edge_id = first[time];
            if (edge_id < 0 || edge_id >= MAX_EVENTS || second[time] < 0 ||
                second[time] > third || third >= (long)vertex_count ||
                used_id[(usz)edge_id]) return -1;
            for (usz prior = 0; prior < MAX_EVENTS; prior += 1)
                if (active[prior] && edge_left[prior] == second[time] &&
                    edge_right[prior] == third) return -1;
            used_id[(usz)edge_id] = true; active[(usz)edge_id] = true;
            start_time[(usz)edge_id] = time;
            edge_left[(usz)edge_id] = second[time]; edge_right[(usz)edge_id] = third;
        } else if (operation[time] == 1) {
            long edge_id = first[time];
            if (edge_id < 0 || edge_id >= MAX_EVENTS || !active[(usz)edge_id] ||
                second[time] != 0 || third != 0) return -1;
            active[(usz)edge_id] = false;
        } else if (operation[time] == 2) {
            if (first[time] != 0 || second[time] != 0 || third != 0) return -1;
            query_count += 1;
        } else return -1;
    }

    usz required = 8 * query_count;
    if (output == null || capacity < required) return -2;
    usz[TREE_NODES] bucket_count = zeroed;
    usz[TREE_NODES][MAX_EVENTS] buckets;
    for (usz edge_id = 0; edge_id < MAX_EVENTS; edge_id += 1) {
        if (!used_id[edge_id]) continue;
        usz end_time = event_count;
        if (!active[edge_id]) {
            for (usz time = start_time[edge_id] + 1; time < event_count; time += 1)
                if (operation[time] == 1 && first[time] == (long)edge_id) {
                    end_time = time; break;
                }
        }
        if (start_time[edge_id] < end_time && event_count != 0)
            add_interval(1, 0, event_count, start_time[edge_id], end_time,
                edge_id, &bucket_count[0], &buckets[0]);
    }

    usz[MAX_VERTICES] parent, set_size, xor_parent;
    for (usz vertex = 0; vertex < vertex_count; vertex += 1) {
        parent[vertex] = vertex; set_size[vertex] = 1; xor_parent[vertex] = 0;
    }
    usz[MAX_EVENTS] history_kind, history_child, history_root, history_size, history_xor;
    usz history_count = 0; usz contradictions = 0;
    long[MAX_EVENTS] answer = zeroed;
    if (event_count != 0)
        solve_time_tree(1, 0, event_count, &operation[0], &first[0], &second[0],
            &edge_left[0], &edge_right[0], &bucket_count[0], &buckets[0],
            &parent[0], &set_size[0], &xor_parent[0], &history_kind[0],
            &history_child[0], &history_root[0], &history_size[0], &history_xor[0],
            &history_count, &contradictions, &answer[0]);
    usz written = 0;
    for (usz time = 0; time < event_count; time += 1)
        if (operation[time] == 2) { store_i64_le(output, written, answer[time]); written += 8; }
    return (long)written;
}
