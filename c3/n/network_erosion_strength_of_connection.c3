module network_erosion_strength_of_connection;

const int SOC_MAX_VERTICES = 8;
const usz SOC_MAX_PARSEABLE_INPUT = 117;

fn int soc_shortest_path(long* adjacency, int n, int source, int target, int* path) {
    int[8] distance;
    int[8] predecessor;
    int[8] queue;
    for (int vertex = 0; vertex < n; vertex++) {
        distance[vertex] = -1;
        predecessor[vertex] = -1;
    }
    int head = 0, tail = 0;
    queue[tail++] = source;
    distance[source] = 0;
    while (head < tail) {
        int vertex = queue[head++];
        for (int successor = 0; successor < n; successor++) {
            long bit = 1L << successor;
            if ((adjacency[vertex] & bit) != 0 && distance[successor] == -1) {
                distance[successor] = distance[vertex] + 1;
                predecessor[successor] = vertex;
                queue[tail++] = successor;
            }
        }
    }
    if (distance[target] == -1) return 0;
    int[8] reversed;
    int count = 0;
    for (int vertex = target; vertex != -1; vertex = predecessor[vertex]) {
        reversed[count++] = vertex;
        if (vertex == source) break;
    }
    if (reversed[count - 1] != source) return 0;
    for (int index = 0; index < count; index++) path[index] = reversed[count - index - 1];
    return count;
}

fn long soc_gcd(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn void soc_write_i64(char* output, int word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[(usz)word * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long network_erosion_strength_of_connection(long* input, usz length, char* output,
                                                usz capacity) @export("network_erosion_strength_of_connection") {
    if (input == null || length < 4 || length > SOC_MAX_PARSEABLE_INPUT) return -1;
    long vertex_raw = input[0], edge_raw = input[1];
    long source_raw = input[2], target_raw = input[3];
    if (vertex_raw < 2 || vertex_raw > SOC_MAX_VERTICES || edge_raw < 0 ||
        edge_raw > vertex_raw * (vertex_raw - 1) || source_raw < 0 || source_raw >= vertex_raw ||
        target_raw < 0 || target_raw >= vertex_raw || source_raw == target_raw) return -1;
    int n = (int)vertex_raw, edge_count = (int)edge_raw;
    int source = (int)source_raw, target = (int)target_raw;
    if (length != (usz)(4 + 2 * edge_count)) return -1;

    long[8] adjacency = {0};
    usz cursor = 4;
    for (int edge = 0; edge < edge_count; edge++) {
        long from_raw = input[cursor++], to_raw = input[cursor++];
        if (from_raw < 0 || from_raw >= n || to_raw < 0 || to_raw >= n || from_raw == to_raw)
            return -1;
        int from = (int)from_raw, to = (int)to_raw;
        long bit = 1L << to;
        if ((adjacency[from] & bit) != 0) return -1;
        adjacency[from] |= bit;
    }

    int[8] distances;
    for (int vertex = 0; vertex < n; vertex++) distances[vertex] = -1;
    int[8] path;
    int first_count = soc_shortest_path(adjacency, n, source, target, path);
    if (first_count != 0) {
        int initial_length = first_count - 1;
        distances[source] = initial_length;
        distances[target] = initial_length;
        while (true) {
            int path_count = soc_shortest_path(adjacency, n, source, target, path);
            if (path_count == 0) break;
            int path_length = path_count - 1;
            if (path_length == 1) {
                adjacency[source] &= ~(1L << target);
                continue;
            }
            for (int index = 0; index < path_count; index++) {
                int vertex = path[index];
                if (distances[vertex] == -1) distances[vertex] = path_length;
            }
            for (int index = 1; index + 1 < path_count; index++) {
                int vertex = path[index];
                long bit = 1L << vertex;
                adjacency[vertex] = 0;
                for (int other = 0; other < n; other++) adjacency[other] &= ~bit;
            }
        }
    }

    long reciprocal_sum_scaled = 0;
    for (int vertex = 0; vertex < n; vertex++)
        if (distances[vertex] >= 1) reciprocal_sum_scaled += 420 / distances[vertex];
    long numerator = 2 * reciprocal_sum_scaled;
    long denominator = 420 * (n + 2);
    if (numerator == 0) denominator = 1;
    else {
        long divisor = soc_gcd(numerator, denominator);
        numerator /= divisor;
        denominator /= divisor;
    }
    if (output == null || capacity < 16) return -2;
    soc_write_i64(output, 0, numerator);
    soc_write_i64(output, 1, denominator);
    return 16;
}
