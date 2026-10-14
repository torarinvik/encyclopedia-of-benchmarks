module level_order_traversal;

fn long level_order_traversal(long* nodes, usz node_count, long root_index,
        long* output_values, usz output_capacity, usz* level_offsets,
        usz level_offsets_capacity, usz* queue, usz queue_capacity)
    @export("level_order_traversal")
{
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (level_offsets == null || level_offsets_capacity < 1) return -2;
        level_offsets[0] = 0;
        return 0;
    }
    if (node_count > 4096 || nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    if (output_values == null || output_capacity < node_count || level_offsets == null ||
        level_offsets_capacity < node_count + 1 || queue == null || queue_capacity < node_count) return -2;

    usz head = 0;
    usz tail = 1;
    usz visited = 0;
    usz levels = 0;
    queue[0] = (usz)root_index;
    level_offsets[0] = 0;
    while (head < tail) {
        usz level_end = tail;
        while (head < level_end) {
            usz node = queue[head];
            head++;
            output_values[visited] = nodes[3 * node];
            visited++;
            long left = nodes[3 * node + 1];
            long right = nodes[3 * node + 2];
            if (left < -1 || right < -1 ||
                (left >= 0 && (usz)left >= node_count) ||
                (right >= 0 && (usz)right >= node_count)) return -1;
            if (left >= 0) {
                if (tail >= queue_capacity || tail >= node_count) return -1;
                queue[tail] = (usz)left;
                tail++;
            }
            if (right >= 0) {
                if (tail >= queue_capacity || tail >= node_count) return -1;
                queue[tail] = (usz)right;
                tail++;
            }
        }
        levels++;
        level_offsets[levels] = visited;
    }
    if (visited != node_count) return -1;
    return (long)levels;
}
