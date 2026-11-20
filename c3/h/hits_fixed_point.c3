module hits_fixed_point;

const long MAX_VERTICES = 16;
const long MAX_EDGES = 64;
const long SCORE_SCALE = 1000000;

fn long hits_fixed_point(long* input, usz length) @export("hits_fixed_point") {
    if (input == null || length < 3 || length > 132) return -1;

    long vertex_count_value = input[0];
    long edge_count_value = input[1];
    long iteration_count_value = input[2];
    if (vertex_count_value < 1 || vertex_count_value > MAX_VERTICES ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES ||
        iteration_count_value < 0 || iteration_count_value > 32) return -1;

    usz vertex_count = (usz)vertex_count_value;
    usz edge_count = (usz)edge_count_value;
    usz iteration_count = (usz)iteration_count_value;
    if (length != 3 + 2 * edge_count) return -1;

    usz[64] sources = zeroed;
    usz[64] targets = zeroed;
    bool[256] seen = zeroed;
    for (usz edge = 0; edge < edge_count; edge++) {
        long source_value = input[3 + 2 * edge];
        long target_value = input[4 + 2 * edge];
        if (source_value < 0 || source_value >= vertex_count_value ||
            target_value < 0 || target_value >= vertex_count_value ||
            source_value == target_value) return -1;
        usz source = (usz)source_value;
        usz target = (usz)target_value;
        usz seen_index = source * MAX_VERTICES.usz() + target;
        if (seen[seen_index]) return -1;
        seen[seen_index] = true;
        sources[edge] = source;
        targets[edge] = target;
    }

    long[16] hubs = zeroed;
    long[16] authorities = zeroed;
    for (usz vertex = 0; vertex < vertex_count; vertex++) hubs[vertex] = SCORE_SCALE;

    for (usz iteration = 0; iteration < iteration_count; iteration++) {
        long[16] raw = zeroed;
        for (usz edge = 0; edge < edge_count; edge++)
            raw[targets[edge]] += hubs[sources[edge]];
        long total = 0;
        for (usz vertex = 0; vertex < vertex_count; vertex++) total += raw[vertex];
        for (usz vertex = 0; vertex < vertex_count; vertex++)
            authorities[vertex] = total == 0 ? 0 : raw[vertex] * SCORE_SCALE / total;

        for (usz vertex = 0; vertex < vertex_count; vertex++) raw[vertex] = 0;
        for (usz edge = 0; edge < edge_count; edge++)
            raw[sources[edge]] += authorities[targets[edge]];
        total = 0;
        for (usz vertex = 0; vertex < vertex_count; vertex++) total += raw[vertex];
        for (usz vertex = 0; vertex < vertex_count; vertex++)
            hubs[vertex] = total == 0 ? 0 : raw[vertex] * SCORE_SCALE / total;
    }

    long result = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex++)
        result += (vertex + 1).long() * (authorities[vertex] + 65537 * hubs[vertex]);
    return result;
}
