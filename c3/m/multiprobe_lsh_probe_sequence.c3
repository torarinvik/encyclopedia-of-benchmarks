module multiprobe_lsh_probe_sequence;

fn long mpls_key(int mask, int* distances, int n) {
    long score = 0, bits = 0;
    for (int i = 0; i < n; i += 1) if ((mask & (1 << i)) != 0) { score += (long)distances[i]*distances[i]; bits += 1; }
    return score*2304 + bits*256 + mask;
}
fn int mpls_push(int* heap, int size, int mask, int* distances, int n) {
    int at = size; long key = mpls_key(mask, distances, n);
    while (at > 0 && key < mpls_key(heap[(at-1)/2], distances, n)) { heap[at] = heap[(at-1)/2]; at = (at-1)/2; }
    heap[at] = mask; return size+1;
}
fn int mpls_pop(int* heap, int size, int* distances, int n) {
    int result = heap[0], remaining = size-1, last = heap[remaining], at = 0;
    while (2*at+1 < remaining) {
        int child = 2*at+1;
        if (child+1 < remaining && mpls_key(heap[child+1], distances, n) < mpls_key(heap[child], distances, n)) child += 1;
        if (mpls_key(heap[child], distances, n) >= mpls_key(last, distances, n)) break;
        heap[at] = heap[child]; at = child;
    }
    if (remaining > 0) heap[at] = last;
    return result;
}
long multiprobe_lsh_probe_sequence(long* input, usz length, char* output, usz capacity) @export("multiprobe_lsh_probe_sequence") {
    if (input == null || length < 4 || length > 7 || input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 1000) return -1;
    int m = (int)input[0], width = (int)input[1], limit = 1;
    for (int i = 0; i < m; i += 1) limit *= 3;
    if (length != (usz)(3+m) || input[2] < 0 || input[2] >= limit) return -1;
    int count = (int)input[2];
    int[8] distances = zeroed, coords = zeroed, signs = zeroed;
    for (int i = 0; i < m; i += 1) {
        if (input[3+i] < 0 || input[3+i] > width) return -1;
        distances[2*i] = (int)input[3+i]; distances[2*i+1] = width-distances[2*i];
        coords[2*i] = coords[2*i+1] = i; signs[2*i] = -1; signs[2*i+1] = 1;
    }
    for (int i = 1; i < 2*m; i += 1) {
        int d = distances[i], c = coords[i], s = signs[i], j = i;
        while (j > 0 && (distances[j-1] > d || (distances[j-1] == d && (coords[j-1] > c || (coords[j-1] == c && signs[j-1] > s))))) {
            distances[j] = distances[j-1]; coords[j] = coords[j-1]; signs[j] = signs[j-1]; j -= 1;
        }
        distances[j] = d; coords[j] = c; signs[j] = s;
    }
    int[256] heap = zeroed; char[80] result = zeroed;
    int size = mpls_push(&heap[0], 0, 1, &distances[0], 2*m), emitted = 0;
    while (emitted < count) {
        int mask = mpls_pop(&heap[0], size, &distances[0], 2*m); size -= 1;
        int top = 0; while ((1 << (top+1)) <= mask) top += 1;
        if (top+1 < 2*m) {
            size = mpls_push(&heap[0], size, (mask ^ (1 << top)) | (1 << (top+1)), &distances[0], 2*m);
            size = mpls_push(&heap[0], size, mask | (1 << (top+1)), &distances[0], 2*m);
        }
        int seen = 0; bool valid = true;
        for (int i = 0; i < 2*m; i += 1) if ((mask & (1 << i)) != 0) {
            int bit = 1 << coords[i]; if ((seen & bit) != 0) { valid = false; break; } seen |= bit;
        }
        if (valid) { result[emitted] = (char)mask; emitted += 1; }
    }
    if (output == null || capacity < (usz)count) return -2;
    for (int i = 0; i < count; i += 1) output[i] = result[i];
    return (long)count;
}
