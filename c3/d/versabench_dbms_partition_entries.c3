module versabench_dbms_partition_entries;
const MAX_FAN = 8;
const MAX_INPUT_LENGTH = 1 + 8 * (MAX_FAN + 1);

fn bool valid_box(long* v, usz at) {
    for (usz d = 0; d < 4; d++) if (v[at+d] < -8 || v[at+d] > 8 || v[at+4+d] < -8 || v[at+4+d] > 8 || v[at+d] >= v[at+4+d]) return false;
    return true;
}
fn long volume_at(long* v, usz at) {
    long product = 1; for (usz d = 0; d < 4; d++) product *= v[at+4+d] - v[at+d]; return product;
}
fn long union_volume(long* v, usz left, usz right) {
    long product = 1;
    for (usz d = 0; d < 4; d++) {
        long lo = v[left+d]; if (v[right+d] < lo) lo = v[right+d];
        long hi = v[left+4+d]; if (v[right+4+d] > hi) hi = v[right+4+d];
        product *= hi - lo;
    }
    return product;
}
fn long penalty(long* v, usz seed, usz entry) { return union_volume(v, seed, entry) - volume_at(v, seed); }

fn long versabench_dbms_partition_entries(long* values, usz length) @export("versabench_dbms_partition_entries") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH + 1) return -1;
    long raw_fan = values[0]; if (raw_fan < 2 || raw_fan > MAX_FAN) return -1;
    usz fan = (usz)raw_fan; usz count = fan + 1;
    if (length != 1 + 8 * count) return -1;
    for (usz i = 0; i < count; i++) if (!valid_box(values, 1 + 8 * i)) return -1;
    usz seed_a = 0; usz seed_b = 1; long largest = union_volume(values, 1, 9);
    for (usz i = 0; i < count; i++) for (usz j = i + 1; j < count; j++) {
        long candidate = union_volume(values, 1 + 8 * i, 1 + 8 * j);
        if (candidate > largest) { largest = candidate; seed_a = i; seed_b = j; }
    }
    usz a_at = 1 + 8 * seed_a; usz b_at = 1 + 8 * seed_b;
    usz size_a = 1; usz size_b = 1; long mask = 1L << seed_a;
    for (usz i = 0; i < count; i++) {
        if (i == seed_a || i == seed_b) continue;
        usz at = 1 + 8 * i;
        if (size_a < fan && size_b < fan) {
            if (penalty(values, a_at, at) < penalty(values, b_at, at)) { mask |= 1L << i; size_a++; }
            else size_b++;
        } else if (size_a >= fan && size_b < fan) size_b++;
        else if (size_b >= fan && size_a < fan) { mask |= 1L << i; size_a++; }
        else return -1;
    }
    return mask;
}
