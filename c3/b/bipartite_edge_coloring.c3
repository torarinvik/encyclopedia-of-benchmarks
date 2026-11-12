module bipartite_edge_coloring;

const usz MAX_SIDE_VERTICES = 5;
const usz MAX_EDGES = 10;
const usz MAX_INPUT_LENGTH = 23;
const usz MAX_OUTPUT_BYTES = 88;

struct Context {
    long[25] multiplicity;
    long[25] original_remaining;
    usz[5] left_degree;
    usz[5] right_degree;
    uint8[5] seen;
    int[5] match_right;
}

fn bool augment_matching(Context* context, usz left, usz side) {
    for (usz right = 0; right < side; right++) {
        usz index = left * MAX_SIDE_VERTICES + right;
        if (context->multiplicity[index] == 0 || context->seen[right] != 0) continue;
        context->seen[right] = 1;
        int matched = context->match_right[right];
        if (matched < 0 || augment_matching(context, (usz)matched, side)) {
            context->match_right[right] = (int)left;
            return true;
        }
    }
    return false;
}

fn long bipartite_edge_coloring(long* input, usz length, uint8* output,
        usz output_capacity) @export("bipartite_edge_coloring") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long left_value = input[0];
    long right_value = input[1];
    long edge_value = input[2];
    if (left_value < 1 || left_value > 5 || right_value < 1 || right_value > 5 ||
        edge_value < 1 || edge_value > 10) return -1;
    usz left_count = (usz)left_value;
    usz right_count = (usz)right_value;
    usz edge_count = (usz)edge_value;
    if (length != 3 + 2 * edge_count) return -1;

    Context context = {};
    long[10] left_edges;
    long[10] right_edges;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_value_edge = input[3 + 2 * edge];
        long right_value_edge = input[4 + 2 * edge];
        if (left_value_edge < 0 || left_value_edge >= left_value ||
            right_value_edge < 0 || right_value_edge >= right_value) return -1;
        usz left = (usz)left_value_edge;
        usz right = (usz)right_value_edge;
        left_edges[edge] = left_value_edge;
        right_edges[edge] = right_value_edge;
        usz index = left * MAX_SIDE_VERTICES + right;
        context.multiplicity[index]++;
        context.original_remaining[index]++;
        context.left_degree[left]++;
        context.right_degree[right]++;
    }

    usz side = left_count > right_count ? left_count : right_count;
    usz maximum_degree = 0;
    for (usz vertex = 0; vertex < side; vertex++) {
        if (context.left_degree[vertex] > maximum_degree) maximum_degree = context.left_degree[vertex];
        if (context.right_degree[vertex] > maximum_degree) maximum_degree = context.right_degree[vertex];
    }
    while (true) {
        usz left = 0;
        while (left < side && context.left_degree[left] == maximum_degree) left++;
        if (left == side) break;
        usz right = 0;
        while (right < side && context.right_degree[right] == maximum_degree) right++;
        if (right == side) return -1;
        context.multiplicity[left * MAX_SIDE_VERTICES + right]++;
        context.left_degree[left]++;
        context.right_degree[right]++;
    }

    long[10] colors;
    for (usz edge = 0; edge < edge_count; edge++) colors[edge] = -1;
    for (usz color = 0; color < maximum_degree; color++) {
        for (usz right = 0; right < side; right++) context.match_right[right] = -1;
        for (usz left = 0; left < side; left++) {
            for (usz right = 0; right < side; right++) context.seen[right] = 0;
            if (!augment_matching(&context, left, side)) return -1;
        }
        for (usz right = 0; right < side; right++) {
            int matched = context.match_right[right];
            if (matched < 0) return -1;
            usz left = (usz)matched;
            usz index = left * MAX_SIDE_VERTICES + right;
            if (context.original_remaining[index] > 0) {
                usz edge = 0;
                while (edge < edge_count && (colors[edge] >= 0 || left_edges[edge] != (long)left ||
                       right_edges[edge] != (long)right)) edge++;
                if (edge == edge_count) return -1;
                colors[edge] = (long)color;
                context.original_remaining[index]--;
            }
            context.multiplicity[index]--;
        }
    }

    usz bytes = 8 * (edge_count + 1);
    if (output == null || output_capacity < bytes) return -2;
    ulong[88] staged = zeroed;
    ulong color_count = (ulong)maximum_degree;
    for (usz byte = 0; byte < 8; byte++) staged[byte] = (color_count >> (8 * byte)) & 255;
    for (usz edge = 0; edge < edge_count; edge++)
        for (usz byte = 0; byte < 8; byte++)
            staged[8 * (edge + 1) + byte] = ((ulong)colors[edge] >> (8 * byte)) & 255;
    for (usz byte = 0; byte < bytes; byte++) output[byte] = (uint8)staged[byte];
    return (long)bytes;
}
