module topological_sort_dfs;

// Deterministic depth-first topological sort with three-color cycle detection.
fn long topological_sort_dfs(long* values, usz length, char* output, usz output_capacity)
    @export("topological_sort_dfs")
{
    if (values == null || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 40) return -2;
    usz vertices = (usz)values[0];
    usz edge_count = (length - 1) / 2;
    ulong[40] adjacency;
    char[40] state;
    usz[40] stack, next_neighbor, order;
    for (usz vertex = 0; vertex < 40; vertex++) {
        adjacency[vertex] = 0ul;
        state[vertex] = 0;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin_value = values[1 + 2 * edge];
        long destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (ulong)origin_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -2;
        usz origin = (usz)origin_value;
        usz destination = (usz)destination_value;
        adjacency[origin] = adjacency[origin] | (1ul << (ulong)destination);
    }

    usz count = 0;
    for (usz root = 0; root < vertices; root++) {
        if (state[root] != 0) continue;
        usz top = 0;
        stack[top] = root;
        next_neighbor[top] = 0;
        state[root] = 1;
        while (true) {
            usz origin = stack[top];
            usz destination = next_neighbor[top];
            while (destination < vertices &&
                (adjacency[origin] & (1ul << (ulong)destination)) == 0ul) destination++;
            if (destination == vertices) {
                state[origin] = 2;
                order[count] = origin;
                count++;
                if (top == 0) break;
                top--;
                continue;
            }
            next_neighbor[top] = destination + 1;
            if (state[destination] == 1) return -1;
            if (state[destination] == 0) {
                top++;
                stack[top] = destination;
                next_neighbor[top] = 0;
                state[destination] = 1;
            }
        }
    }

    if (output_capacity < vertices || (vertices != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) output[index] = (char)order[count - 1 - index];
    return (long)count;
}
