module depth_first_search;

// Traverse the directed graph from start using an explicit fixed-capacity graph.
fn long depth_first_search(long* values, usz length, char* output, usz output_capacity)
    @export("depth_first_search")
{
    if (values == null || length < 2 || length > 66 || (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    usz vertices = (usz)values[0];
    long start_value = values[1];
    if (vertices == 0) return start_value == -1 && length == 2 ? 0 : -2;
    if (start_value < 0 || (ulong)start_value >= (ulong)vertices) return -2;
    ulong[64] adjacency;
    bool[64] visited;
    usz[64] order;
    for (usz vertex = 0; vertex < 64; vertex++) {
        adjacency[vertex] = 0ul;
        visited[vertex] = false;
    }
    usz edge_count = (length - 2) / 2;
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin_value = values[2 + 2 * edge];
        long destination_value = values[3 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (ulong)origin_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -2;
        usz origin = (usz)origin_value;
        usz destination = (usz)destination_value;
        adjacency[origin] |= 1ul << (ulong)destination;
    }
    usz start = (usz)start_value;
    usz count = 0;
    visited[start] = true;
    usz[64] stack_vertex;
    usz[64] stack_next;
    usz depth = 1;
    stack_vertex[0] = start;
    stack_next[0] = 0;
    order[count++] = start;
    while (depth != 0) {
        usz frame = depth - 1;
        usz origin = stack_vertex[frame];
        if (stack_next[frame] == vertices) {
            depth--;
            continue;
        }
        usz destination = stack_next[frame]++;
        if ((adjacency[origin] & (1ul << (ulong)destination)) != 0ul && !visited[destination]) {
            visited[destination] = true;
            order[count++] = destination;
            stack_vertex[depth] = destination;
            stack_next[depth] = 0;
            depth++;
        }
    }
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) output[index] = (char)order[index];
    return (long)count;
}
