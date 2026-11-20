module dynamic_centroid_active_set_diameter;

const usz MAX_N = 32;
const usz MAX_OPERATIONS = 64;
const usz MAX_LEVELS = 6;
const usz MAX_PARSEABLE_LENGTH = 98;

fn long component_size(usz n, long* adjacency, long* blocked,
                      long* subtree_size, usz vertex, long parent) {
    long total = 1;
    for (usz neighbor = 0; neighbor < n; neighbor += 1) {
        if (adjacency[vertex * n + neighbor] != 0
                && (long)neighbor != parent && blocked[neighbor] == 0) {
            total += component_size(n, adjacency, blocked, subtree_size,
                                   neighbor, (long)vertex);
        }
    }
    subtree_size[vertex] = total;
    return total;
}

fn usz choose_centroid(usz n, long* adjacency, long* blocked,
                       long* subtree_size, usz vertex, long parent, long total) {
    for (usz neighbor = 0; neighbor < n; neighbor += 1) {
        if (adjacency[vertex * n + neighbor] != 0
                && (long)neighbor != parent && blocked[neighbor] == 0
                && subtree_size[neighbor] > total / 2) {
            return choose_centroid(n, adjacency, blocked, subtree_size,
                                   neighbor, (long)vertex, total);
        }
    }
    return vertex;
}

fn void record_component(usz n, usz level, long* adjacency, long* blocked,
                         long* record_count, long* record_centroid,
                         long* record_branch, long* record_distance,
                         usz centroid, usz vertex, long parent, long distance,
                         usz branch) {
    if (level >= MAX_LEVELS) return;
    usz index = vertex * MAX_LEVELS + level;
    record_centroid[index] = (long)centroid;
    record_branch[index] = vertex == centroid ? (long)n : (long)branch;
    record_distance[index] = distance;
    record_count[vertex] = (long)(level + 1);
    for (usz neighbor = 0; neighbor < n; neighbor += 1) {
        if (adjacency[vertex * n + neighbor] != 0
                && (long)neighbor != parent && blocked[neighbor] == 0) {
            usz next_branch = vertex == centroid ? neighbor : branch;
            record_component(n, level, adjacency, blocked, record_count,
                             record_centroid, record_branch, record_distance,
                             centroid, neighbor, (long)vertex, distance + 1,
                             next_branch);
        }
    }
}

fn void build_centroid_records(usz n, usz level, long* adjacency,
                               long* blocked, long* subtree_size,
                               long* record_count, long* record_centroid,
                               long* record_branch, long* record_distance,
                               usz entry) {
    if (level >= MAX_LEVELS) return;
    long total = component_size(n, adjacency, blocked, subtree_size, entry, -1);
    usz centroid = choose_centroid(n, adjacency, blocked, subtree_size,
                                   entry, -1, total);
    record_component(n, level, adjacency, blocked, record_count,
                     record_centroid, record_branch, record_distance,
                     centroid, centroid, -1, 0, n);
    blocked[centroid] = 1;
    for (usz neighbor = 0; neighbor < n; neighbor += 1) {
        if (adjacency[centroid * n + neighbor] != 0 && blocked[neighbor] == 0) {
            build_centroid_records(n, level + 1, adjacency, blocked,
                                   subtree_size, record_count, record_centroid,
                                   record_branch, record_distance, neighbor);
        }
    }
}

fn void recompute_branch(usz n, long* active, long* record_count,
                         long* record_centroid, long* record_branch,
                         long* record_distance, long* best,
                         usz centroid, usz branch) {
    best[centroid * (n + 1) + branch] = -1;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        if (active[vertex] == 0) continue;
        for (long record = 0; record < record_count[vertex]; record += 1) {
            usz index = vertex * MAX_LEVELS + (usz)record;
            if (record_centroid[index] == (long)centroid
                    && record_branch[index] == (long)branch
                    && record_distance[index] > best[centroid * (n + 1) + branch]) {
                best[centroid * (n + 1) + branch] = record_distance[index];
            }
        }
    }
}

fn long active_diameter(usz n, long* best) {
    long answer = 0;
    for (usz centroid = 0; centroid < n; centroid += 1) {
        long first = -1, second = -1;
        for (usz branch = 0; branch <= n; branch += 1) {
            long distance = best[centroid * (n + 1) + branch];
            if (distance > first) {
                second = first;
                first = distance;
            } else if (distance > second) {
                second = distance;
            }
        }
        if (second >= 0 && first + second > answer) answer = first + second;
    }
    return answer;
}

fn long dynamic_centroid_active_set_diameter(long* input, usz length)
    @export("dynamic_centroid_active_set_diameter")
{
    if (input == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N
            || q_value < 0 || q_value > (long)MAX_OPERATIONS) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != n + 1 + q) return -1;

    long[MAX_N * MAX_N] adjacency;
    long[MAX_N] blocked, subtree_size, record_count, active;
    long[MAX_N * MAX_LEVELS] record_centroid, record_branch, record_distance;
    long[MAX_N * (MAX_N + 1)] best;
    for (usz i = 0; i < MAX_N * MAX_N; i += 1) adjacency[i] = 0;
    for (usz i = 0; i < MAX_N; i += 1) {
        blocked[i] = 0;
        subtree_size[i] = 0;
        record_count[i] = 0;
        active[i] = 0;
    }
    for (usz vertex = 1; vertex < n; vertex += 1) {
        long parent_value = input[vertex + 1];
        if (parent_value < 0 || parent_value >= (long)vertex) return -1;
        usz parent = (usz)parent_value;
        adjacency[parent * n + vertex] = 1;
        adjacency[vertex * n + parent] = 1;
    }
    for (usz i = 0; i < q; i += 1) {
        long operation = input[n + 1 + i];
        if (operation != -1 && (operation < 0 || operation >= (long)n)) return -1;
    }
    build_centroid_records(n, 0, &adjacency[0], &blocked[0], &subtree_size[0],
                           &record_count[0], &record_centroid[0],
                           &record_branch[0], &record_distance[0], 0);
    for (usz centroid = 0; centroid < n; centroid += 1)
        for (usz branch = 0; branch <= n; branch += 1)
            best[centroid * (n + 1) + branch] = -1;

    long checksum = 0, query_number = 0;
    for (usz i = 0; i < q; i += 1) {
        long operation = input[n + 1 + i];
        if (operation == -1) {
            query_number += 1;
            checksum += query_number * (active_diameter(n, &best[0]) + 1);
            continue;
        }
        usz vertex = (usz)operation;
        active[vertex] = active[vertex] == 0 ? 1 : 0;
        for (long record = 0; record < record_count[vertex]; record += 1) {
            usz index = vertex * MAX_LEVELS + (usz)record;
            usz centroid = (usz)record_centroid[index];
            usz branch = (usz)record_branch[index];
            long distance = record_distance[index];
            if (active[vertex] != 0) {
                if (distance > best[centroid * (n + 1) + branch])
                    best[centroid * (n + 1) + branch] = distance;
            } else if (best[centroid * (n + 1) + branch] == distance) {
                recompute_branch(n, &active[0], &record_count[0],
                                 &record_centroid[0], &record_branch[0],
                                 &record_distance[0], &best[0], centroid, branch);
            }
        }
    }
    return checksum;
}
