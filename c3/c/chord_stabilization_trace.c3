module chord_stabilization_trace;

fn bool chord_between(int* ids, int ring, int left, int item, int right) {
    int distance = (ids[item]-ids[left]+ring)%ring, span = (ids[right]-ids[left]+ring)%ring;
    return distance > 0 && (span == 0 || distance < span);
}
long chord_stabilization_trace(long* input, usz length, char* output, usz capacity) @export("chord_stabilization_trace") {
    if (input == null || length < 6 || length > 115 || input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > 64) return -1;
    int ring = 1 << (int)input[0], n = (int)input[1], q = (int)input[2];
    if (n > ring || length != (usz)(3+3*n+q)) return -1;
    int[16] ids = zeroed, succ = zeroed, pred = zeroed;
    for (int i = 0; i < n; i += 1) {
        if (input[3+i] < 0 || input[3+i] >= ring || (i > 0 && input[3+i] <= ids[i-1]) || input[3+n+i] < 0 || input[3+n+i] >= n || input[3+2*n+i] < -1 || input[3+2*n+i] >= n) return -1;
        ids[i] = (int)input[3+i]; succ[i] = (int)input[3+n+i]; pred[i] = (int)input[3+2*n+i];
    }
    for (int i = 0; i < q; i += 1) if (input[3+3*n+i] < 0 || input[3+3*n+i] >= n) return -1;
    for (int i = 0; i < q; i += 1) {
        int node = (int)input[3+3*n+i], candidate = pred[succ[node]];
        if (candidate >= 0 && chord_between(&ids[0], ring, node, candidate, succ[node])) succ[node] = candidate;
        int receiver = succ[node];
        if (pred[receiver] < 0 || chord_between(&ids[0], ring, pred[receiver], node, receiver)) pred[receiver] = node;
    }
    if (output == null || capacity < (usz)(2*n)) return -2;
    for (int i = 0; i < n; i += 1) { output[i] = (char)succ[i]; output[n+i] = pred[i] < 0 ? (char)255 : (char)pred[i]; }
    return 2*n;
}
