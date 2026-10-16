module greedy_graph_coloring;

const long MAX_VERTICES = 14;

fn long greedy_graph_coloring(long* values, usz length) @export("greedy_graph_coloring") {
    if (values == null || length < 1 || length > MAX_VERTICES + 1) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > MAX_VERTICES || length != (usz)(count_value + 1)) return -1;
    int count = (int)count_value;
    long limit = (1L << count) - 1;
    long[MAX_VERTICES] adjacency = {};
    int[MAX_VERTICES] degree = {};
    int[MAX_VERTICES] order = {};
    int[MAX_VERTICES] colors = {};
    for (int vertex = 0; vertex < count; vertex++) {
        long mask = values[1 + (usz)vertex];
        if (mask < 0 || mask > limit || (mask & (1L << vertex)) != 0) return -1;
        adjacency[vertex] = mask;
        long remaining = mask;
        while (remaining != 0) { remaining &= remaining - 1; degree[vertex]++; }
        order[vertex] = vertex;
    }
    for (int vertex = 0; vertex < count; vertex++)
        for (int other = 0; other < count; other++)
            if (((adjacency[vertex] >> other) & 1) != ((adjacency[other] >> vertex) & 1)) return -1;
    for (int index = 1; index < count; index++) {
        int current = order[index];
        int position = index;
        while (position > 0 && degree[order[position - 1]] < degree[current]) {
            order[position] = order[position - 1];
            position--;
        }
        order[position] = current;
    }
    int color_count = 0;
    for (int position = 0; position < count; position++) {
        int vertex = order[position];
        int[MAX_VERTICES + 1] used = {};
        for (int other = 0; other < count; other++)
            if ((adjacency[vertex] & (1L << other)) != 0 && colors[other] != 0) used[colors[other]] = 1;
        int color = 1;
        while (used[color] != 0) color++;
        colors[vertex] = color;
        if (color > color_count) color_count = color;
    }
    long packed = color_count;
    for (int vertex = 0; vertex < count; vertex++) packed |= (long)colors[vertex] << (4 * (vertex + 1));
    return packed;
}
