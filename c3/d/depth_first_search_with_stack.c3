module depth_first_search_with_stack;

// Stack-based DFS that marks vertices when they are pushed, matching the source order.
fn long depth_first_search_with_stack(long* values, usz length, char* output, usz output_capacity)
    @export("depth_first_search_with_stack")
{
    if (values == null || length < 2 || length > 66 || (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    usz vertices = (usz)values[0];
    long start_value = values[1];
    if (vertices == 0) return start_value == -1 && length == 2 ? 0 : -2;
    if (start_value < 0 || (ulong)start_value >= (ulong)vertices) return -2;

    usz[2048] adjacency;
    usz[64] degree;
    char[64] state;
    for (usz vertex = 0; vertex < 64; vertex++) {
        degree[vertex] = 0;
        state[vertex] = 0;
    }
    usz edge_count = (length - 2) / 2;
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin_value = values[2 + 2 * edge];
        long destination_value = values[3 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (ulong)origin_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -2;
        usz origin = (usz)origin_value;
        adjacency[origin * 32 + degree[origin]++] = (usz)destination_value;
    }

    usz[33] stack;
    usz[64] order;
    usz stack_length = 1;
    usz count = 0;
    usz start = (usz)start_value;
    state[start] = 1;
    stack[0] = start;
    while (stack_length != 0) {
        stack_length--;
        usz vertex = stack[stack_length];
        if (state[vertex] != 1) continue;
        order[count++] = vertex;
        for (usz edge = 0; edge < degree[vertex]; edge++) {
            usz neighbor = adjacency[vertex * 32 + edge];
            stack[stack_length++] = neighbor;
            if (state[neighbor] != 2) state[neighbor] = 1;
        }
        state[vertex] = 2;
    }
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) output[index] = (char)order[index];
    return (long)count;
}
