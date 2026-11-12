module offline_dynamic_connectivity;

const int MAX_VERTICES = 16;
const int MAX_EVENTS = 32;
const usz MAX_INPUT_VALUES = 2 + 4 * MAX_EVENTS + 1;
const int TREE_NODES = 4 * MAX_EVENTS + 8;

fn usz find_root(usz[MAX_VERTICES]* parent, usz vertex) {
    while (parent[vertex] != vertex) vertex = parent[vertex];
    return vertex;
}

fn void add_interval(usz node, usz left, usz right, usz query_left,
    usz query_right, usz edge_id, usz[MAX_TREE_NODES]* bucket_count,
    usz[MAX_TREE_NODES][MAX_EVENTS]* buckets) {
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

fn void unite(usz left, usz right, usz[MAX_VERTICES]* parent,
    usz[MAX_VERTICES]* set_size, usz[MAX_VERTICES]* history_child,
    usz[MAX_VERTICES]* history_root, usz[MAX_VERTICES]* history_size,
    usz* history_count) {
    usz root_left = find_root(parent, left);
    usz root_right = find_root(parent, right);
    if (root_left == root_right) return;
    if (set_size[root_left] > set_size[root_right]) {
        usz temporary = root_left;
        root_left = root_right;
        root_right = temporary;
    }
    history_child[*history_count] = root_left;
    history_root[*history_count] = root_right;
    history_size[*history_count] = set_size[root_right];
    *history_count += 1;
    parent[root_left] = root_right;
    set_size[root_right] += set_size[root_left];
}

fn void rollback_to(usz checkpoint, usz[MAX_VERTICES]* parent,
    usz[MAX_VERTICES]* set_size, usz[MAX_VERTICES]* history_child,
    usz[MAX_VERTICES]* history_root, usz[MAX_VERTICES]* history_size,
    usz* history_count) {
    while (*history_count > checkpoint) {
        *history_count -= 1;
        usz child = history_child[*history_count];
        usz root = history_root[*history_count];
        parent[child] = child;
        set_size[root] = history_size[*history_count];
    }
}

fn void solve_time_tree(usz node, usz left, usz right,
    long[MAX_EVENTS]* operation, long[MAX_EVENTS]* first,
    long[MAX_EVENTS]* second, long[MAX_EVENTS]* edge_left,
    long[MAX_EVENTS]* edge_right, usz[MAX_TREE_NODES]* bucket_count,
    usz[MAX_TREE_NODES][MAX_EVENTS]* buckets, usz[MAX_VERTICES]* parent,
    usz[MAX_VERTICES]* set_size, usz[MAX_VERTICES]* history_child,
    usz[MAX_VERTICES]* history_root, usz[MAX_VERTICES]* history_size,
    usz* history_count, long[MAX_EVENTS]* answer) {
    usz checkpoint = *history_count;
    for (usz entry = 0; entry < bucket_count[node]; entry += 1) {
        usz edge_id = buckets[node][entry];
        unite((usz)edge_left[edge_id], (usz)edge_right[edge_id], parent,
              set_size, history_child, history_root, history_size, history_count);
    }
    if (right - left == 1) {
        if (operation[left] == 2)
            answer[left] = find_root(parent, (usz)first[left]) ==
                           find_root(parent, (usz)second[left]) ? 1 : 0;
    } else {
        usz middle = left + (right - left) / 2;
        solve_time_tree(2 * node, left, middle, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            history_child, history_root, history_size, history_count, answer);
        solve_time_tree(2 * node + 1, middle, right, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, parent, set_size,
            history_child, history_root, history_size, history_count, answer);
    }
    rollback_to(checkpoint, parent, set_size, history_child, history_root,
                history_size, history_count);
}

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (uint8)((bits >> (8 * byte)) & 255);
}

fn long offline_dynamic_connectivity(long* input, usz length, uint8* output,
    usz capacity) @export("offline_dynamic_connectivity") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EVENTS) return -1;
    usz vertex_count = (usz)input[0], event_count = (usz)input[1];
    if (length != 2 + 4 * event_count) return -1;

    long[MAX_EVENTS] operation, first, second, edge_left, edge_right;
    usz[MAX_EVENTS] start_time;
    bool[MAX_EVENTS] used_id = zeroed, active = zeroed;
    usz query_count = 0;
    for (usz time = 0; time < event_count; time += 1) {
        usz offset = 2 + 4 * time;
        operation[time] = input[offset];
        first[time] = input[offset + 1];
        second[time] = input[offset + 2];
        long third = input[offset + 3];
        if (operation[time] == 0) {
            long edge_id = first[time];
            if (edge_id < 0 || edge_id >= MAX_EVENTS || second[time] < 0 ||
                second[time] >= (long)vertex_count || third < 0 ||
                third >= (long)vertex_count || used_id[(usz)edge_id]) return -1;
            used_id[(usz)edge_id] = true;
            active[(usz)edge_id] = true;
            start_time[(usz)edge_id] = time;
            edge_left[(usz)edge_id] = second[time];
            edge_right[(usz)edge_id] = third;
        } else if (operation[time] == 1) {
            long edge_id = first[time];
            if (edge_id < 0 || edge_id >= MAX_EVENTS || !active[(usz)edge_id] ||
                second[time] != 0 || third != 0) return -1;
            active[(usz)edge_id] = false;
        } else if (operation[time] == 2) {
            if (first[time] < 0 || first[time] >= (long)vertex_count ||
                second[time] < 0 || second[time] >= (long)vertex_count || third != 0)
                return -1;
            query_count += 1;
        } else return -1;
    }

    usz required = 8 * query_count;
    if (output == null || capacity < required) return -2;
    usz[MAX_TREE_NODES] bucket_count = zeroed;
    usz[MAX_TREE_NODES][MAX_EVENTS] buckets;
    for (usz edge_id = 0; edge_id < MAX_EVENTS; edge_id += 1) {
        if (!used_id[edge_id]) continue;
        usz end_time = event_count;
        if (!active[edge_id]) {
            for (usz time = start_time[edge_id] + 1; time < event_count; time += 1) {
                if (operation[time] == 1 && first[time] == (long)edge_id) {
                    end_time = time;
                    break;
                }
            }
        }
        if (start_time[edge_id] < end_time && event_count != 0)
            add_interval(1, 0, event_count, start_time[edge_id], end_time,
                         edge_id, &bucket_count, &buckets);
    }

    usz[MAX_VERTICES] parent, set_size;
    for (usz vertex = 0; vertex < vertex_count; vertex += 1) {
        parent[vertex] = vertex;
        set_size[vertex] = 1;
    }
    usz[MAX_VERTICES] history_child, history_root, history_size;
    usz history_count = 0;
    long[MAX_EVENTS] answer = zeroed;
    if (event_count != 0)
        solve_time_tree(1, 0, event_count, &operation, &first, &second,
            &edge_left, &edge_right, &bucket_count, &buckets, &parent, &set_size,
            &history_child, &history_root, &history_size, &history_count, &answer);

    usz written = 0;
    for (usz time = 0; time < event_count; time += 1) {
        if (operation[time] == 2) {
            store_i64_le(output, written, answer[time]);
            written += 8;
        }
    }
    return (long)written;
}
