module directed_simple_cycles;

const usz MAX_VERTICES = 6;
const usz MAX_EDGES = MAX_VERTICES * MAX_VERTICES;
const usz MAX_OUTPUT_BYTES = 2786;

fn long directed_simple_cycles(long* input, usz length, char* output, usz capacity) @export("directed_simple_cycles") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_VERTICES ||
        input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertices = (usz)input[0];
    usz edges = (usz)input[1];
    if (length != 2 + 2 * edges) return -1;

    bool[MAX_VERTICES][MAX_VERTICES] adjacency = zeroed;
    for (usz edge = 0; edge < edges; edge++) {
        long source = input[2 + 2 * edge];
        long destination = input[3 + 2 * edge];
        if (source < 0 || source >= (long)vertices || destination < 0 || destination >= (long)vertices) return -1;
        adjacency[(usz)source][(usz)destination] = true;
    }

    char[MAX_OUTPUT_BYTES] scratch = zeroed;
    usz output_length = 0;
    for (usz start = 0; start < vertices; start++) {
        usz[MAX_VERTICES] path = zeroed;
        usz[MAX_VERTICES] next_neighbor = zeroed;
        bool[MAX_VERTICES] visited = zeroed;
        usz depth = 0;
        path[0] = start;
        visited[start] = true;
        while true {
            usz current = path[depth];
            if (next_neighbor[depth] == vertices) {
                visited[current] = false;
                if (depth == 0) break;
                depth--;
                continue;
            }
            usz neighbor = next_neighbor[depth];
            next_neighbor[depth]++;
            if (!adjacency[current][neighbor]) continue;
            if (neighbor == start) {
                for (usz index = 0; index <= depth; index++) scratch[output_length++] = (char)path[index];
                scratch[output_length++] = (char)start;
                scratch[output_length++] = (char)255;
            } else if (!visited[neighbor]) {
                depth++;
                path[depth] = neighbor;
                next_neighbor[depth] = 0;
                visited[neighbor] = true;
            }
        }
        for (usz vertex = 0; vertex < vertices; vertex++) {
            adjacency[start][vertex] = false;
            adjacency[vertex][start] = false;
        }
    }
    if (output_length == 0) return 0;
    if (output == null || capacity < output_length) return -2;
    for (usz index = 0; index < output_length; index++) output[index] = (u8)scratch[index];
    return (long)output_length;
}
