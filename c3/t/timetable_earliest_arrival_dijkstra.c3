module timetable_earliest_arrival_dijkstra;

const usz MAX_N = 8;
const usz MAX_ARCS = 12;
const usz MAX_TRIPS = 4;
const usz MAX_OUTPUT_BYTES = 88;
const long INF = 1000000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long timetable_earliest_arrival_dijkstra(long* input, usz length, char* output, usz capacity)
        @export("timetable_earliest_arrival_dijkstra") {
    if (input == null || length < 5 || length > 138) return -1;
    long n_raw = input[0], arc_count_raw = input[1], source_raw = input[2], target_raw = input[3], start_time = input[4];
    if (n_raw < 2 || n_raw > MAX_N.long() || arc_count_raw < 0 || arc_count_raw > MAX_ARCS.long() ||
            source_raw < 0 || source_raw >= n_raw || target_raw < 0 || target_raw >= n_raw || start_time < 0 || start_time > 1000) return -1;
    usz n = n_raw.usz(), arc_count = arc_count_raw.usz(), source = source_raw.usz(), target = target_raw.usz();
    int[MAX_ARCS] arc_u, arc_v, trip_count;
    long[MAX_ARCS][MAX_TRIPS] departure = zeroed, arrival = zeroed;
    usz cursor = 5;
    for (usz edge = 0; edge < arc_count; edge += 1) {
        if (cursor + 3 > length) return -1;
        long u_raw = input[cursor], v_raw = input[cursor + 1], count_raw = input[cursor + 2]; cursor += 3;
        if (u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw || u_raw == v_raw || count_raw < 1 || count_raw > MAX_TRIPS.long() || cursor + 2 * count_raw.usz() > length) return -1;
        usz u = u_raw.usz(), v = v_raw.usz(), count = count_raw.usz();
        for (usz prior = 0; prior < edge; prior += 1) if (arc_u[prior] == u.int() && arc_v[prior] == v.int()) return -1;
        arc_u[edge] = u.int(); arc_v[edge] = v.int(); trip_count[edge] = count.int();
        for (usz trip = 0; trip < count; trip += 1) {
            long dep = input[cursor], arr = input[cursor + 1]; cursor += 2;
            if (dep < 0 || dep > 1000 || arr <= dep || arr > 2000 ||
                    (trip > 0 && (dep <= departure[edge][trip - 1] || arr < arrival[edge][trip - 1]))) return -1;
            departure[edge][trip] = dep; arrival[edge][trip] = arr;
        }
    }
    if (cursor != length) return -1;

    long[MAX_N] distance;
    int[MAX_N] parent;
    bool[MAX_N] settled = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) { distance[vertex] = INF; parent[vertex] = -1; }
    distance[source] = start_time;
    for (usz step = 0; step < n; step += 1) {
        int chosen = -1;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if (!settled[vertex] && distance[vertex] < INF &&
                    (chosen < 0 || distance[vertex] < distance[chosen.usz()] ||
                     (distance[vertex] == distance[chosen.usz()] && vertex < chosen.usz()))) chosen = vertex.int();
        }
        if (chosen < 0) break;
        settled[chosen.usz()] = true;
        for (usz edge = 0; edge < arc_count; edge += 1) {
            usz v = arc_v[edge].usz();
            if (arc_u[edge] != chosen || settled[v]) continue;
            usz trip = 0;
            while (trip < trip_count[edge].usz() && departure[edge][trip] < distance[chosen.usz()]) trip += 1;
            if (trip == trip_count[edge].usz()) continue;
            long candidate = arrival[edge][trip];
            if (candidate < distance[v] || (candidate == distance[v] && (parent[v] < 0 || chosen < parent[v]))) {
                distance[v] = candidate; parent[v] = chosen;
            }
        }
    }

    int[MAX_N] reverse_path;
    usz path_length = 0;
    if (distance[target] < INF) {
        int current = target.int();
        reverse_path[path_length] = current; path_length += 1;
        while (current != source.int() && path_length < n) {
            if (parent[current.usz()] < 0) { path_length = 0; break; }
            current = parent[current.usz()];
            reverse_path[path_length] = current; path_length += 1;
        }
        if (path_length == 0 || reverse_path[path_length - 1] != source.int()) path_length = 0;
    }
    bool reachable = path_length > 0;
    usz output_bytes = if reachable then 8 * (3 + path_length) else 24;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, if reachable then 1 else 0);
    store_i64_le(&staged[0], 8, if reachable then distance[target] else -1);
    store_i64_le(&staged[0], 16, path_length.long());
    if (reachable) for (usz i = 0; i < path_length; i += 1)
        store_i64_le(&staged[0], 24 + 8 * i, reverse_path[path_length - 1 - i].long());
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
