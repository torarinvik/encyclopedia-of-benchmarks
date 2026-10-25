module versabench_dbms_choose_entry;
const MAX_CHILDREN = 8;
const MAX_INPUT_LENGTH = 1 + 8 * MAX_CHILDREN + 8;

fn bool valid_box(long* v, usz at) {
    for (usz d = 0; d < 4; d++)
        if (v[at + d] < -8 || v[at + d] > 8 || v[at + 4 + d] < -8 || v[at + 4 + d] > 8 || v[at + d] >= v[at + 4 + d]) return false;
    return true;
}
fn long volume_at(long* v, usz at) {
    long result = 1;
    for (usz d = 0; d < 4; d++) result *= v[at + 4 + d] - v[at + d];
    return result;
}
fn long penalty_at(long* v, usz child, usz incoming) {
    long joined_volume = 1;
    for (usz d = 0; d < 4; d++) {
        long child_lo = v[child + d]; long incoming_lo = v[incoming + d];
        long child_hi = v[child + 4 + d]; long incoming_hi = v[incoming + 4 + d];
        long lo = child_lo; if (incoming_lo < lo) lo = incoming_lo;
        long hi = child_hi; if (incoming_hi > hi) hi = incoming_hi;
        joined_volume *= hi - lo;
    }
    return joined_volume - volume_at(v, child);
}
fn long versabench_dbms_choose_entry(long* values, usz length) @export("versabench_dbms_choose_entry") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH + 1) return -1;
    long raw_count = values[0]; if (raw_count < 1 || raw_count > MAX_CHILDREN) return -1;
    usz count = (usz)raw_count; if (length != 1 + 8 * count + 8) return -1;
    usz incoming = 1 + 8 * count;
    for (usz i = 0; i < count; i++) if (!valid_box(values, 1 + 8 * i)) return -1;
    if (!valid_box(values, incoming)) return -1;
    usz best = 0; long best_penalty = penalty_at(values, 1, incoming);
    for (usz i = 1; i < count; i++) { long candidate = penalty_at(values, 1 + 8 * i, incoming); if (candidate < best_penalty) { best = i; best_penalty = candidate; } }
    return (long)best;
}
