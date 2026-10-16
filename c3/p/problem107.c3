module problem107;

const usz MAX_VERTICES = 40;
const long MAX_EDGE_WEIGHT = 999;

fn long edge_weight(long* input, usz left, usz right) {
    if (left == right) return -1;
    usz row = left > right ? left : right;
    usz column = left > right ? right : left;
    return input[1 + row * (row - 1) / 2 + column];
}

fn long problem107(long* input, usz length) @export("problem107") {
    if (input == null || length < 1) return -1;
    long vertex_count_value = input[0];
    if (vertex_count_value < 1 || vertex_count_value > MAX_VERTICES.long()) return -1;
    usz vertex_count = (usz)vertex_count_value;
    if (length != 1 + vertex_count * (vertex_count - 1) / 2) return -1;

    long total_weight = 0;
    for (usz index = 1; index < length; index++) {
        if (input[index] < -1 || input[index] > MAX_EDGE_WEIGHT) return -1;
        if (input[index] >= 0) total_weight += input[index];
    }

    bool[MAX_VERTICES] selected;
    long[MAX_VERTICES] best_weight;
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        selected[vertex] = false;
        best_weight[vertex] = MAX_EDGE_WEIGHT + 1;
    }
    best_weight[0] = 0;
    long tree_weight = 0;
    for (usz iteration = 0; iteration < vertex_count; iteration++) {
        usz next_vertex = vertex_count;
        long next_weight = MAX_EDGE_WEIGHT + 1;
        for (usz vertex = 0; vertex < vertex_count; vertex++) {
            if (!selected[vertex] && best_weight[vertex] < next_weight) {
                next_vertex = vertex;
                next_weight = best_weight[vertex];
            }
        }
        if (next_vertex == vertex_count) return -1;
        selected[next_vertex] = true;
        tree_weight += next_weight;
        for (usz vertex = 0; vertex < vertex_count; vertex++) {
            if (selected[vertex]) continue;
            long weight = edge_weight(input, next_vertex, vertex);
            if (weight >= 0 && weight < best_weight[vertex]) best_weight[vertex] = weight;
        }
    }
    return total_weight - tree_weight;
}
