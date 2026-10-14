module topological_sort;

// Kahn topological sort over a bounded directed graph encoded as edge pairs.
fn long topological_sort(long* values, usz length, char* output, usz output_capacity)
    @export("topological_sort")
{
    if (values == null || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    usz vertices = (usz)values[0];
    usz edge_count = (length - 1) / 2;
    ulong[64] adjacency;
    usz[64] indegree, queue, order;
    for (usz vertex = 0; vertex < 64; vertex++) {
        adjacency[vertex] = 0ul;
        indegree[vertex] = 0;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin_value = values[1 + 2 * edge];
        long destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (ulong)origin_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -2;
        usz origin = (usz)origin_value;
        usz destination = (usz)destination_value;
        ulong mask = 1ul << (ulong)destination;
        if ((adjacency[origin] & mask) == 0ul) {
            adjacency[origin] |= mask;
            indegree[destination]++;
        }
    }
    usz head = 0;
    usz tail = 0;
    for (usz vertex = 0; vertex < vertices; vertex++) {
        if (indegree[vertex] == 0) queue[tail++] = vertex;
    }
    usz count = 0;
    while (head < tail) {
        usz origin = queue[head++];
        order[count++] = origin;
        for (usz destination = 0; destination < vertices; destination++) {
            if ((adjacency[origin] & (1ul << (ulong)destination)) != 0ul) {
                indegree[destination]--;
                if (indegree[destination] == 0) queue[tail++] = destination;
            }
        }
    }
    if (count != vertices) return -1;
    if (output_capacity < vertices || (vertices != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) output[index] = (char)order[index];
    return (long)count;
}
