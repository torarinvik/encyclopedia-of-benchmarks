module gapbs_afforest_components;

const long MAX_N = 16;
const long MAX_M = 64;
const long MAX_SAMPLES = 64;

fn void link_components(long u, long v, long* component) {
    long p1 = component[u], p2 = component[v];
    while (p1 != p2) {
        long high = p1 > p2 ? p1 : p2;
        long low = p1 + (p2 - high);
        long parent_high = component[high];
        if (parent_high == low) break;
        if (parent_high == high) { component[high] = low; break; }
        p1 = component[component[high]];
        p2 = component[low];
    }
}

fn void compress_components(usz n, long* component) {
    for (usz vertex = 0; vertex < n; vertex += 1)
        while (component[vertex] != component[(usz)component[vertex]])
            component[vertex] = component[(usz)component[vertex]];
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt.
long gapbs_afforest_components(long* input, usz length, char* output, usz capacity)
        @export("gapbs_afforest_components") {
    if (input == null || length < 4 || length > 195) return -1;
    long n64 = input[0], m64 = input[1], sample_count64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || sample_count64 < 1 || sample_count64 > MAX_SAMPLES ||
        length != 3 + (usz)sample_count64 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64, sample_count = (usz)sample_count64;
    usz[MAX_SAMPLES] samples;
    for (usz i = 0; i < sample_count; i += 1) {
        long sample = input[3 + i];
        if (sample < 0 || sample >= n64) return -1;
        samples[i] = (usz)sample;
    }
    bool[MAX_N][MAX_N] adjacency = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        usz pos = 3 + sample_count + 2 * edge;
        long u = input[pos], v = input[pos + 1];
        if (u < 0 || v <= u || v >= n64 || adjacency[(usz)u][(usz)v]) return -1;
        adjacency[(usz)u][(usz)v] = true;
        adjacency[(usz)v][(usz)u] = true;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N][MAX_N] neighbors = zeroed;
    usz[MAX_N] degree = zeroed;
    for (usz u = 0; u < n; u += 1)
        for (usz v = 0; v < n; v += 1)
            if (adjacency[u][v]) { neighbors[u][degree[u]] = (long)v; degree[u] += 1; }
    long[MAX_N] component;
    for (usz vertex = 0; vertex < n; vertex += 1) component[vertex] = (long)vertex;
    for (usz round = 0; round < 2; round += 1) {
        for (usz u = 0; u < n; u += 1)
            if (degree[u] > round) link_components((long)u, neighbors[u][round], &component[0]);
        compress_components(n, &component[0]);
    }
    long[MAX_N] sample_counts = zeroed;
    for (usz i = 0; i < sample_count; i += 1) sample_counts[(usz)component[samples[i]]] += 1;
    long skip_label = 0;
    for (usz label = 1; label < n; label += 1)
        if (sample_counts[label] > sample_counts[(usz)skip_label]) skip_label = (long)label;
    bool skip_is_safe = true;
    for (usz u = 0; u < n && skip_is_safe; u += 1) {
        if (component[u] != skip_label) continue;
        for (usz offset = 2; offset < degree[u]; offset += 1)
            if (component[(usz)neighbors[u][offset]] != skip_label) { skip_is_safe = false; break; }
    }
    for (usz u = 0; u < n; u += 1) {
        if (skip_is_safe && component[u] == skip_label) continue;
        for (usz offset = 2; offset < degree[u]; offset += 1)
            link_components((long)u, neighbors[u][offset], &component[0]);
    }
    compress_components(n, &component[0]);
    for (usz vertex = 0; vertex < n; vertex += 1) store_i64_le(output, 8 * vertex, component[vertex]);
    return (long)output_bytes;
}
