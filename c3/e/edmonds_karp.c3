module edmonds_karp;

const usz MAX_VERTICES = 16;
const long MAX_CAPACITY = 1000000;

fn long edmonds_karp(long* input, usz length) @export("edmonds_karp") {
    if (input == null || length < 3) return -1;
    long n64 = input[0], source64 = input[1], sink64 = input[2];
    if (n64 < 1 || n64 > MAX_VERTICES || source64 < 0 || source64 >= n64 ||
        sink64 < 0 || sink64 >= n64) return -1;
    usz n = (usz)n64;
    if (length != 3 + n * n) return -1;

    long[MAX_VERTICES * MAX_VERTICES] residual;
    for (usz row = 0; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            long capacity = input[3 + row * n + column];
            if (capacity < 0 || capacity > MAX_CAPACITY || (row == column && capacity != 0)) return -1;
            residual[row * n + column] = capacity;
        }
    }
    for (usz left = 0; left < n; left++)
        for (usz right = left + 1; right < n; right++)
            if (residual[left * n + right] > 0 && residual[right * n + left] > 0) return -1;

    usz source = (usz)source64, sink = (usz)sink64;
    if (source == sink) return 0;
    long total_flow = 0;
    while (true) {
        long[MAX_VERTICES] parent;
        usz[MAX_VERTICES] queue;
        for (usz vertex = 0; vertex < n; vertex++) parent[vertex] = -1;
        parent[source] = (long)source;
        usz head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] == -1) {
            usz node = queue[head++];
            for (usz neighbor = 0; neighbor < n; neighbor++) {
                if (residual[node * n + neighbor] <= 0 || parent[neighbor] != -1) continue;
                parent[neighbor] = (long)node;
                if (neighbor == sink) break;
                queue[tail++] = neighbor;
            }
        }
        if (parent[sink] == -1) return total_flow;
        long path_flow = MAX_CAPACITY;
        for (usz node = sink; node != source; node = (usz)parent[node]) {
            usz previous = (usz)parent[node];
            if (residual[previous * n + node] < path_flow) path_flow = residual[previous * n + node];
        }
        for (usz node = sink; node != source; node = (usz)parent[node]) {
            usz previous = (usz)parent[node];
            residual[previous * n + node] -= path_flow;
            residual[node * n + previous] += path_flow;
        }
        total_flow += path_flow;
    }
}
