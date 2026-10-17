module johnsons_algorithm;

const long MAX_VERTICES = 16;
const usz MAX_INPUT_LENGTH = 257;
const long MAX_WEIGHT = 32;
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

fn long johnsons_algorithm(long* input, usz length) @export("johnsons_algorithm") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long vertex_value = input[0];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES) return -1;
    usz vertices = (usz)vertex_value;
    if (length != 1 + vertices * vertices) return -1;

    long[MAX_VERTICES * MAX_VERTICES] weight = {0};
    bool[MAX_VERTICES * MAX_VERTICES] edge = {false};
    bool[MAX_VERTICES * MAX_VERTICES] reachable = {false};
    for (usz from = 0; from < vertices; from++) {
        reachable[from * MAX_VERTICES + from] = true;
        for (usz to = 0; to < vertices; to++) {
            long value = input[1 + from * vertices + to];
            if (value < -MAX_WEIGHT || value > MAX_WEIGHT) return -1;
            if (from != to && value != 0) {
                usz index = from * MAX_VERTICES + to;
                edge[index] = true;
                weight[index] = value;
                reachable[index] = true;
            }
        }
    }
    for (usz intermediate = 0; intermediate < vertices; intermediate++)
        for (usz from = 0; from < vertices; from++)
            for (usz to = 0; to < vertices; to++) {
                usz index = from * MAX_VERTICES + to;
                reachable[index] = reachable[index] ||
                    (reachable[from * MAX_VERTICES + intermediate] &&
                     reachable[intermediate * MAX_VERTICES + to]);
            }
    for (usz from = 0; from < vertices; from++)
        for (usz to = 0; to < vertices; to++)
            if (!reachable[from * MAX_VERTICES + to]) return -1;

    long[MAX_VERTICES] potential = {0};
    for (usz iteration = 1; iteration < vertices; iteration++) {
        bool updated = false;
        for (usz from = 0; from < vertices; from++)
            for (usz to = 0; to < vertices; to++) {
                usz index = from * MAX_VERTICES + to;
                if (!edge[index]) continue;
                long candidate = potential[from] + weight[index];
                if (candidate < potential[to]) {
                    potential[to] = candidate;
                    updated = true;
                }
            }
        if (!updated) break;
    }
    for (usz from = 0; from < vertices; from++)
        for (usz to = 0; to < vertices; to++) {
            usz index = from * MAX_VERTICES + to;
            if (!edge[index]) continue;
            if (potential[from] + weight[index] < potential[to] ||
                weight[index] + potential[from] - potential[to] <= 0) return -1;
        }

    long[MAX_VERTICES * MAX_VERTICES] reweighted = {0};
    for (usz from = 0; from < vertices; from++)
        for (usz to = 0; to < vertices; to++) {
            usz index = from * MAX_VERTICES + to;
            if (edge[index]) reweighted[index] = weight[index] + potential[from] - potential[to];
        }

    ulong result = FNV_OFFSET_BASIS;
    for (usz source = 0; source < vertices; source++) {
        long[MAX_VERTICES] distance;
        bool[MAX_VERTICES] visited = {false};
        for (usz vertex = 0; vertex < vertices; vertex++) distance[vertex] = UNREACHABLE;
        distance[source] = 0;
        for (usz step = 0; step < vertices; step++) {
            usz current = vertices;
            for (usz vertex = 0; vertex < vertices; vertex++)
                if (!visited[vertex] && (current == vertices || distance[vertex] <= distance[current])) current = vertex;
            if (current == vertices || distance[current] == UNREACHABLE) break;
            visited[current] = true;
            for (usz next = 0; next < vertices; next++) {
                usz index = current * MAX_VERTICES + next;
                if (!edge[index] || visited[next]) continue;
                long candidate = distance[current] + reweighted[index];
                if (candidate < distance[next]) distance[next] = candidate;
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
