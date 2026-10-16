module find_isolated_nodes;

// Return vertices with no outgoing neighbors, in ascending vertex order.
fn long find_isolated_nodes(long* values, usz length, char* output, usz output_capacity)
    @export("find_isolated_nodes")
{
    if (values == null || length < 1 || length > 65 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    usz vertices = (usz)values[0];
    ulong[64] adjacency;
    for (usz vertex = 0; vertex < 64; vertex++) adjacency[vertex] = 0ul;
    usz edge_count = (length - 1) / 2;
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin_value = values[1 + 2 * edge];
        long destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (ulong)origin_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -2;
        usz origin = (usz)origin_value;
        usz destination = (usz)destination_value;
        adjacency[origin] |= 1ul << (ulong)destination;
    }
    char[64] isolated;
    usz count = 0;
    for (usz vertex = 0; vertex < vertices; vertex++) {
        if (adjacency[vertex] == 0ul) isolated[count++] = (char)vertex;
    }
    if (output_capacity < count || (count != 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) output[index] = isolated[index];
    return (long)count;
}
