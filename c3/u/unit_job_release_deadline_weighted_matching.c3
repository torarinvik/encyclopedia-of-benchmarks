module unit_job_release_deadline_weighted_matching;

fn bool ujs_assign(int job, int* starts, int* ends, int* slots, bool* seen) {
    for (int slot = starts[job]; slot <= ends[job]; slot++) {
        if (seen[slot]) continue;
        seen[slot] = true;
        int old = slots[slot];
        if (old < 0 || ujs_assign(old, starts, ends, slots, seen)) {
            slots[slot] = job;
            return true;
        }
    }
    return false;
}

fn long unit_job_release_deadline_weighted_matching(long* input, usz length) @export("unit_job_release_deadline_weighted_matching") {
    if (input == null || length < 1 || length > 98 || input[0] < 0 || input[0] > 32) return -1;
    int n = (int)input[0];
    if (length != (1+3*n).usz()) return -1;
    int[32] starts, ends, slots, order;
    long[32] weights;
    for (int i = 0; i < 32; i++) slots[i] = -1;
    for (int i = 0; i < n; i++) {
        long r = input[1+3*i], d = input[2+3*i], w = input[3+3*i];
        if (r < 0 || d < r || d >= 32 || w < 0 || w > 1000000) return -1;
        starts[i] = (int)r; ends[i] = (int)d; weights[i] = w;
        int j = i;
        while (j > 0 && weights[order[j-1]] < w) { order[j] = order[j-1]; j--; }
        order[j] = i;
    }
    long total = 0;
    for (int i = 0; i < n; i++) {
        bool[32] seen = {false};
        int job = order[i];
        if (ujs_assign(job, &starts[0], &ends[0], &slots[0], &seen[0])) total += weights[job];
    }
    return total;
}
