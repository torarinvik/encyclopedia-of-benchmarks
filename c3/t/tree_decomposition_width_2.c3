module tree_decomposition_width_2;

const int MAX_N = 32;
const int MAX_M = 64;
const int MAX_INPUT = 131;
const int MAX_OUTPUT = 1592;

fn void put_i64(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long tree_decomposition_width_2(long *values, usz length, char *output, usz capacity)
    @export("tree_decomposition_width_2") {
    if (values == null || length < 2 || length > MAX_INPUT || values[0] < 1 ||
        values[0] > MAX_N || values[1] < 0 || values[1] > MAX_M) return -1;
    int n = (int)values[0];
    int m = (int)values[1];
    if (m > n * (n - 1) / 2 || length != (usz)(2 + 2 * m)) return -1;

    bool[MAX_N][MAX_N] adjacent = {};
    for (int edge = 0; edge < m; edge++) {
        long left0 = values[2 + 2 * edge];
        long right0 = values[3 + 2 * edge];
        if (left0 < 0 || left0 >= right0 || right0 >= n) return -1;
        int left = (int)left0;
        int right = (int)right0;
        if (adjacent[left][right]) return -1;
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    bool[MAX_N] active = {};
    long[MAX_N] order = {};
    long[MAX_N][3] bag_values = {};
    long[MAX_N][2] later = {};
    long[MAX_N] parents = {};
    int[MAX_N] bag_sizes = {};
    int[MAX_N] later_counts = {};
    int[MAX_N] position = {};
    for (int vertex = 0; vertex < n; vertex++) active[vertex] = true;

    for (int step = 0; step < n; step++) {
        int chosen = -1;
        int[2] neighbors = {};
        int count = 0;
        for (int vertex = 0; vertex < n; vertex++) {
            if (!active[vertex]) continue;
            int degree = 0;
            for (int other = 0; other < n; other++)
                if (active[other] && adjacent[vertex][other]) degree++;
            if (degree <= 2) {
                chosen = vertex;
                for (int other = 0; other < n; other++)
                    if (active[other] && adjacent[vertex][other]) {
                        neighbors[count] = other;
                        count++;
                    }
                break;
            }
        }
        if (chosen < 0) return -1;
        order[step] = chosen;
        later_counts[step] = count;
        bag_sizes[step] = count + 1;
        bag_values[step][0] = chosen;
        for (int i = 0; i < count; i++) {
            later[step][i] = neighbors[i];
            bag_values[step][i + 1] = neighbors[i];
        }
        for (int i = 0; i < count + 1; i++) for (int j = i + 1; j < count + 1; j++)
            if (bag_values[step][j] < bag_values[step][i]) {
                long temporary = bag_values[step][i];
                bag_values[step][i] = bag_values[step][j];
                bag_values[step][j] = temporary;
            }
        if (count == 2) {
            adjacent[neighbors[0]][neighbors[1]] = true;
            adjacent[neighbors[1]][neighbors[0]] = true;
        }
        active[chosen] = false;
    }

    for (int step = 0; step < n; step++) position[(int)order[step]] = step;
    for (int step = 0; step < n; step++) {
        parents[step] = n;
        if (later_counts[step] > 0) {
            int selected = (int)later[step][0];
            if (later_counts[step] == 2 && position[(int)later[step][1]] < position[selected])
                selected = (int)later[step][1];
            parents[step] = position[selected];
        }
    }

    usz bytes = (usz)(8 * (6 * n + 7));
    if (bytes > MAX_OUTPUT || output == null || capacity < bytes) return -2;
    char[MAX_OUTPUT] staged = {};
    put_i64(&staged[0], 0, n + 1);
    put_i64(&staged[0], 8, 2);
    put_i64(&staged[0], 16, n);
    usz cursor = 24;
    for (int bag = 0; bag <= n; bag++) {
        int count = bag == n ? 0 : bag_sizes[bag];
        put_i64(&staged[0], cursor, count);
        cursor += 8;
        for (int slot = 0; slot < 3; slot++) {
            long value = slot < count ? bag_values[bag][slot] : -1;
            put_i64(&staged[0], cursor, value);
            cursor += 8;
        }
    }
    for (int child = 0; child < n; child++) {
        put_i64(&staged[0], cursor, child);
        put_i64(&staged[0], cursor + 8, parents[child]);
        cursor += 16;
    }
    for (usz byte = 0; byte < bytes; byte++) output[byte] = staged[byte];
    return (long)bytes;
}
