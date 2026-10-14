module floyd_warshall;

const MAX_VERTICES = 64;
const FLOYD_STORAGE = MAX_VERTICES * MAX_VERTICES;

fn long floyd_warshall(long* edges, usz vertices, usz edge_count, usz source,
                       long* distances, char* reachable) @export("floyd_warshall") {
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (vertices > MAX_VERTICES || source >= vertices) return -3;
    for (usz edge = 0; edge < edge_count; edge++) {
        long origin = edges[3 * edge];
        long destination = edges[3 * edge + 1];
        if (origin < 0 || destination < 0 || (ulong)origin >= vertices || (ulong)destination >= vertices) return -3;
    }
    long[FLOYD_STORAGE] all_distances;
    char[FLOYD_STORAGE] present;
    for (usz index = 0; index < FLOYD_STORAGE; index++) {
        all_distances[index] = 0;
        present[index] = 0;
    }
    for (usz vertex = 0; vertex < vertices; vertex++) present[vertex * vertices + vertex] = 1;
    for (usz edge = 0; edge < edge_count; edge++) {
        usz origin = (usz)edges[3 * edge];
        usz destination = (usz)edges[3 * edge + 1];
        usz index = origin * vertices + destination;
        long weight = edges[3 * edge + 2];
        if (present[index] == 0 || weight < all_distances[index]) {
            all_distances[index] = weight;
            present[index] = 1;
        }
    }
    for (usz middle = 0; middle < vertices; middle++) {
        for (usz origin = 0; origin < vertices; origin++) {
            usz left_index = origin * vertices + middle;
            if (present[left_index] == 0) continue;
            for (usz destination = 0; destination < vertices; destination++) {
                usz right_index = middle * vertices + destination;
                if (present[right_index] == 0) continue;
                long left = all_distances[left_index];
                long right = all_distances[right_index];
                if ((right > 0 && left > 9223372036854775807 - right) ||
                    (right < 0 && left < (-9223372036854775807 - 1) - right)) return -2;
                long candidate = left + right;
                usz index = origin * vertices + destination;
                if (present[index] == 0 || candidate < all_distances[index]) {
                    all_distances[index] = candidate;
                    present[index] = 1;
                }
            }
        }
    }
    for (usz vertex = 0; vertex < vertices; vertex++) {
        usz index = source * vertices + vertex;
        if (present[index] != 0 && present[vertex * vertices + vertex] != 0 && all_distances[vertex * vertices + vertex] < 0) return -1;
    }
    for (usz vertex = 0; vertex < vertices; vertex++) {
        usz index = source * vertices + vertex;
        reachable[vertex] = present[index];
        distances[vertex] = present[index] != 0 ? all_distances[index] : 0;
    }
    return 0;
}
