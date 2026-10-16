module bellman_ford_pair;

const int MAX_VERTICES = 64;
const int MAX_INPUT_EDGES = 256;
const int MAX_NORMALIZED_EDGES = 128;
const long MAX_WEIGHT = 1000;
const long RECORD_BYTES = 24;

fn long write_record(char* output, usz capacity, long status, long reachable, long distance) {
    if (output == null || capacity < 24) return -2;
    long[3] record = {status, reachable, distance};
    for (int field = 0; field < 3; field++) {
        ulong bits = (ulong)record[field];
        for (int byte = 0; byte < 8; byte++)
            output[field * 8 + byte] = (char)(bits >> (byte * 8));
    }
    return RECORD_BYTES;
}

fn long bellman_ford_pair(long* input, usz length, char* output, usz capacity)
    @export("bellman_ford_pair") {
    if (input == null || length < 4) return -1;
    long vertices_value = input[0], input_edges_value = input[1];
    long source_value = input[2], target_value = input[3];
    if (vertices_value < 1 || vertices_value > MAX_VERTICES ||
        input_edges_value < 0 || input_edges_value > MAX_INPUT_EDGES) return -1;
    int vertices = (int)vertices_value, input_edges = (int)input_edges_value;
    if (source_value < 0 || source_value >= vertices_value ||
        target_value < 0 || target_value >= vertices_value || length != (usz)(4 + 3 * input_edges)) return -1;

    long[MAX_VERTICES * MAX_VERTICES] matrix_weights;
    bool[MAX_VERTICES * MAX_VERTICES] matrix_present;
    for (int index = 0; index < MAX_VERTICES * MAX_VERTICES; index++) {
        matrix_weights[index] = 0;
        matrix_present[index] = false;
    }
    int normalized_count = 0;
    for (int edge = 0; edge < input_edges; edge++) {
        long from_value = input[4 + 3 * edge], to_value = input[5 + 3 * edge];
        long weight_value = input[6 + 3 * edge];
        if (from_value < 0 || from_value >= vertices_value || to_value < 0 || to_value >= vertices_value ||
            weight_value < -MAX_WEIGHT || weight_value > MAX_WEIGHT) return -1;
        int key = (int)from_value * vertices + (int)to_value;
        if (!matrix_present[key]) {
            matrix_present[key] = true;
            normalized_count++;
            if (normalized_count > MAX_NORMALIZED_EDGES) return -1;
        }
        matrix_weights[key] = weight_value;
    }

    int[MAX_NORMALIZED_EDGES] from, to;
    long[MAX_NORMALIZED_EDGES] weight;
    int edge_count = 0;
    for (int origin = 0; origin < vertices; origin++) {
        for (int destination = 0; destination < vertices; destination++) {
            int key = origin * vertices + destination;
            if (!matrix_present[key]) continue;
            from[edge_count] = origin;
            to[edge_count] = destination;
            weight[edge_count] = matrix_weights[key];
            edge_count++;
        }
    }

    int source = (int)source_value, target = (int)target_value;
    long[MAX_VERTICES] distance;
    bool[MAX_VERTICES] reachable;
    for (int vertex = 0; vertex < vertices; vertex++) {
        distance[vertex] = 0;
        reachable[vertex] = false;
    }
    reachable[source] = true;
    for (int round = 0; round < vertices; round++) {
        bool changed = false;
        for (int edge = 0; edge < edge_count; edge++) {
            if (!reachable[from[edge]]) continue;
            long candidate = distance[from[edge]] + weight[edge];
            if (!reachable[to[edge]] || candidate < distance[to[edge]]) {
                distance[to[edge]] = candidate;
                reachable[to[edge]] = true;
                changed = true;
            }
        }
        if (!changed) break;
    }
    for (int edge = 0; edge < edge_count; edge++) {
        if (reachable[from[edge]] && distance[to[edge]] > distance[from[edge]] + weight[edge])
            return write_record(output, capacity, -1, 0, 0);
    }
    long target_reachable = reachable[target] ? 1 : 0;
    long target_distance = reachable[target] ? distance[target] : 0;
    return write_record(output, capacity, 0, target_reachable, target_distance);
}
