module dsatur_greedy_coloring;

const int MAX_VERTICES = 12;
const int MAX_EDGES = 66;
const usz MAX_VALID_LENGTH = 134;
const usz MAX_PARSEABLE_LENGTH = 135;

fn int bit_count(ulong value) {
    int count = 0;
    while (value != 0) {
        count += (int)(value & 1ul);
        value >>= 1;
    }
    return count;
}

fn long dsatur_greedy_coloring(long* input, usz length) @export("dsatur_greedy_coloring") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;

    long raw_vertices = input[0];
    long raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > MAX_VERTICES ||
        raw_edges < 0 || raw_edges > MAX_EDGES) return -1;

    usz vertex_count = (usz)raw_vertices;
    usz edge_count = (usz)raw_edges;
    if (length != 2 + 2 * edge_count || length > MAX_VALID_LENGTH) return -1;

    ulong[MAX_VERTICES] adjacency = zeroed;
    for (usz edge = 0; edge < edge_count; edge += 1) {
        long raw_first = input[2 + 2 * edge];
        long raw_second = input[3 + 2 * edge];
        if (raw_first < 0 || raw_first >= raw_second || raw_second >= raw_vertices) return -1;
        usz first = (usz)raw_first;
        usz second = (usz)raw_second;
        ulong first_bit = 1ul << second;
        if ((adjacency[first] & first_bit) != 0) return -1;
        adjacency[first] |= first_bit;
        adjacency[second] |= 1ul << first;
    }

    int[MAX_VERTICES] colors;
    ulong[MAX_VERTICES] saturation_colors = zeroed;
    int[MAX_VERTICES] residual_degree = zeroed;
    for (usz vertex = 0; vertex < vertex_count; vertex += 1) {
        colors[vertex] = -1;
        residual_degree[vertex] = bit_count(adjacency[vertex]);
    }

    int color_count = 0;
    for (usz round = 0; round < vertex_count; round += 1) {
        int selected = -1;
        for (usz vertex = 0; vertex < vertex_count; vertex += 1) {
            if (colors[vertex] >= 0) continue;
            if (selected < 0) {
                selected = (int)vertex;
                continue;
            }
            int saturation = bit_count(saturation_colors[vertex]);
            int selected_saturation = bit_count(saturation_colors[(usz)selected]);
            if (saturation > selected_saturation ||
                (saturation == selected_saturation &&
                 (residual_degree[vertex] > residual_degree[(usz)selected] ||
                  (residual_degree[vertex] == residual_degree[(usz)selected] &&
                   vertex < (usz)selected)))) {
                selected = (int)vertex;
            }
        }

        ulong used = saturation_colors[(usz)selected];
        int color = 0;
        while ((used & (1ul << color)) != 0) color += 1;
        colors[(usz)selected] = color;
        if (color + 1 > color_count) color_count = color + 1;

        for (usz neighbor = 0; neighbor < vertex_count; neighbor += 1) {
            if ((adjacency[(usz)selected] & (1ul << neighbor)) == 0 || colors[neighbor] >= 0) continue;
            residual_degree[neighbor] -= 1;
            saturation_colors[neighbor] |= 1ul << color;
        }
    }

    ulong packed = (ulong)color_count << 48;
    for (usz vertex = 0; vertex < vertex_count; vertex += 1)
        packed |= (ulong)colors[vertex] << (4 * vertex);
    return (long)packed;
}
