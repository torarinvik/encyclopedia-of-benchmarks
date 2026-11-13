module statistical_region_merging_table;

fn usz srm_root(usz* parent, usz x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

long statistical_region_merging_table(long* input, usz length, char* output, usz capacity)
        @export("statistical_region_merging_table") {
    if (input == null || length < 4 || length > 74 || input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6) return -1;
    usz width = (usz)input[1], n = (usz)input[0] * width;
    if (length != 2 + 2*n) return -1;
    for (usz i = 0; i < n; i += 1)
        if (input[2+i] < 0 || input[2+i] > 65535 || input[2+n+i] < 0 || input[2+n+i] > 255) return -1;
    usz[36] parent = zeroed, sizes = zeroed, minimum = zeroed;
    long[36] sums = zeroed;
    for (usz i = 0; i < n; i += 1) { parent[i] = i; minimum[i] = i; sizes[i] = 1; sums[i] = input[2+n+i]; }
    for (long diff = 0; diff < 256; diff += 1) for (usz p = 0; p < n; p += 1) {
        usz[2] neighbors = zeroed; usz count = 0;
        if (p % width + 1 < width) { neighbors[count] = p+1; count += 1; }
        if (p + width < n) { neighbors[count] = p+width; count += 1; }
        for (usz k = 0; k < count; k += 1) {
            usz q = neighbors[k]; long d = input[2+n+p] - input[2+n+q];
            if (d < 0) d = -d;
            if (d != diff) continue;
            usz a = srm_root(&parent[0], p), b = srm_root(&parent[0], q);
            if (a == b) continue;
            long na = (long)sizes[a], nb = (long)sizes[b];
            long delta = sums[a]*nb - sums[b]*na;
            long bound = input[1+sizes[a]] + input[1+sizes[b]];
            if (delta*delta > bound*na*na*nb*nb) continue;
            if (sizes[a] < sizes[b]) { usz t = a; a = b; b = t; }
            parent[b] = a; sizes[a] += sizes[b]; sums[a] += sums[b];
            if (minimum[b] < minimum[a]) minimum[a] = minimum[b];
        }
    }
    if (output == null || capacity < n) return -2;
    for (usz i = 0; i < n; i += 1) output[i] = (char)minimum[srm_root(&parent[0], i)];
    return (long)n;
}
