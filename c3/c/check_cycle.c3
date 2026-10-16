module check_cycle;

const usz MAX_VERTICES = 32;
const usz MAX_EDGES = 256;
const usz MAX_MATRIX = MAX_VERTICES * MAX_VERTICES;

// Detect directed cycles with iterative three-color depth-first search.
fn long check_cycle(long* input, usz length) @export("check_cycle") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_VERTICES ||
        input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertices = (usz)input[0];
    usz edges = (usz)input[1];
    if (length != 2 + 2 * edges) return -1;

    bool[MAX_MATRIX] adjacency = zeroed;
    for (usz edge = 0; edge < edges; edge++) {
        long origin = input[2 + 2 * edge];
        long destination = input[3 + 2 * edge];
        if (origin < 0 || origin >= (long)vertices || destination < 0 || destination >= (long)vertices) return -1;
        adjacency[(usz)origin * MAX_VERTICES + (usz)destination] = true;
    }

    int[MAX_VERTICES] color = zeroed;
    usz[MAX_VERTICES] stack;
    usz[MAX_VERTICES] next_neighbor;
    for (usz start = 0; start < vertices; start++) {
        if (color[start] != 0) continue;
        usz top = 1;
        stack[0] = start;
        next_neighbor[0] = 0;
        color[start] = 1;
        while (top > 0) {
            usz frame = top - 1;
            usz current = stack[frame];
            while (next_neighbor[frame] < vertices &&
                   !adjacency[current * MAX_VERTICES + next_neighbor[frame]]) next_neighbor[frame]++;
            if (next_neighbor[frame] == vertices) {
                color[current] = 2;
                top--;
                continue;
            }
            usz neighbor = next_neighbor[frame]++;
            if (color[neighbor] == 1) return 1;
            if (color[neighbor] == 0) {
                color[neighbor] = 1;
                stack[top] = neighbor;
                next_neighbor[top] = 0;
                top++;
            }
        }
    }
    return 0;
}
