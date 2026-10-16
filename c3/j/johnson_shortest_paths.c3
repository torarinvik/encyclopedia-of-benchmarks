module johnson_shortest_paths;

const long MAX_VERTICES = 32;
const usz MAX_EDGES = 256;
const usz MAX_INPUT_LENGTH = 770;
const usz MAX_QUEUE = 257;
const long UNREACHABLE = 0x7fffffffffffffff;
const long UNREACHABLE_SENTINEL = 0x4000000000000000;
const ulong FNV_OFFSET_BASIS = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong fnv_word(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        hash ^= (bits >> (8 * byte)) & 255;
        hash *= FNV_PRIME;
    }
    return hash;
}

fn long johnson_shortest_paths(long* input, usz length) @export("johnson_shortest_paths") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long vertex_value = input[0], edge_value = input[1];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES) return -1;
    usz vertices = (usz)vertex_value, edges = (usz)edge_value;
    if (length != 2 + 3 * edges) return -1;

    usz[MAX_EDGES] edge_from;
    usz[MAX_EDGES] edge_to;
    long[MAX_EDGES] edge_weight;
    for (usz edge = 0; edge < edges; edge++) {
        long from = input[2 + 3 * edge], to = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (from < 1 || from > vertex_value || to < 1 || to > vertex_value || weight < -32 || weight > 32) return -1;
        edge_from[edge] = (usz)(from - 1);
        edge_to[edge] = (usz)(to - 1);
        edge_weight[edge] = weight;
    }

    long[MAX_VERTICES] potential = {0};
    for (usz iteration = 1; iteration < vertices; iteration++) {
        bool updated = false;
        for (usz edge = 0; edge < edges; edge++) {
            usz from = edge_from[edge], to = edge_to[edge];
            long candidate = potential[from] + edge_weight[edge];
            if (candidate < potential[to]) { potential[to] = candidate; updated = true; }
        }
        if (!updated) break;
    }
    for (usz edge = 0; edge < edges; edge++)
        if (potential[edge_from[edge]] + edge_weight[edge] < potential[edge_to[edge]]) return -1;

    ulong result = FNV_OFFSET_BASIS;
    for (usz source = 0; source < vertices; source++) {
        long[MAX_VERTICES] distance;
        bool[MAX_VERTICES] visited = {false};
        for (usz vertex = 0; vertex < vertices; vertex++) distance[vertex] = UNREACHABLE;
        distance[source] = 0;

        usz[MAX_QUEUE] queue_vertices;
        long[MAX_QUEUE] queue_distances;
        usz queue_length = 1;
        queue_vertices[0] = source;
        queue_distances[0] = 0;
        while (queue_length > 0) {
            usz minimum = 0;
            for (usz index = 1; index < queue_length; index++)
                if (queue_distances[index] < queue_distances[minimum]) minimum = index;
            usz current = queue_vertices[minimum];
            for (usz index = minimum + 1; index < queue_length; index++) {
                queue_vertices[index - 1] = queue_vertices[index];
                queue_distances[index - 1] = queue_distances[index];
            }
            queue_length--;
            if (visited[current]) continue;
            visited[current] = true;

            for (usz edge = 0; edge < edges; edge++) {
                if (edge_from[edge] != current) continue;
                usz next = edge_to[edge];
                long reweighted = edge_weight[edge] + potential[current] - potential[next];
                long candidate = distance[current] + reweighted;
                if (!visited[next] && candidate < distance[next]) {
                    distance[next] = candidate;
                    queue_vertices[queue_length] = next;
                    queue_distances[queue_length] = candidate;
                    queue_length++;
                }
            }
        }

        for (usz destination = 0; destination < vertices; destination++) {
            long output = distance[destination] == UNREACHABLE
                ? UNREACHABLE_SENTINEL
                : distance[destination] - potential[source] + potential[destination];
            result = fnv_word(result, output);
        }
    }
    return (long)(result & 0x7fffffffffffffff);
}
