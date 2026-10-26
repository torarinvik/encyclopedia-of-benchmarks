module hospitals_residents_rgs;
const usz MAX_R = 8; const usz MAX_H = 8; const usz MAX_INPUT = 154; const usz MAX_OUTPUT = 64;

fn void put64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[position + byte] = (char)(bits & 255); bits >>= 8; }
}

long hospitals_residents_rgs(long* input, usz length, char* output, usz capacity) @export("hospitals_residents_rgs") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long r64 = input[0], h64 = input[1];
    if (r64 < 1 || r64 > (long)MAX_R || h64 < 1 || h64 > (long)MAX_H) return -1;
    usz r = (usz)r64, h = (usz)h64;
    usz expected = 2 + 2 * h + r + 2 * r * h;
    if (length != expected) return -1;
    usz cap_offset = 2, rlen_offset = cap_offset + h, rpref_offset = rlen_offset + r;
    usz hlen_offset = rpref_offset + r * h, hpref_offset = hlen_offset + h;
    long[MAX_H] capacities = zeroed, hospital_length = zeroed, occupancy = zeroed;
    long[MAX_R] resident_length = zeroed, assignment = zeroed, next_choice = zeroed;
    long[MAX_R][MAX_H] resident_pref = zeroed;
    long[MAX_H][MAX_R] hospital_rank = zeroed;
    for (usz hospital = 0; hospital < h; hospital += 1) {
        capacities[hospital] = input[cap_offset + hospital];
        hospital_length[hospital] = input[hlen_offset + hospital];
        if (capacities[hospital] < 1 || capacities[hospital] > r64 ||
            hospital_length[hospital] < 0 || hospital_length[hospital] > r64) return -1;
        for (usz resident = 0; resident < r; resident += 1) hospital_rank[hospital][resident] = -1;
    }
    for (usz resident = 0; resident < r; resident += 1) {
        resident_length[resident] = input[rlen_offset + resident];
        if (resident_length[resident] < 0 || resident_length[resident] > h64) return -1;
        bool[MAX_H] seen = zeroed;
        for (usz slot = 0; slot < h; slot += 1) {
            long value = input[rpref_offset + resident * h + slot];
            if (slot < (usz)resident_length[resident]) {
                if (value < 0 || value >= h64 || seen[(usz)value]) return -1;
                seen[(usz)value] = true;
                resident_pref[resident][slot] = value;
            } else {
                if (value != -1) return -1;
                resident_pref[resident][slot] = -1;
            }
        }
        assignment[resident] = -1;
    }
    for (usz hospital = 0; hospital < h; hospital += 1) {
        bool[MAX_R] seen = zeroed;
        for (usz slot = 0; slot < r; slot += 1) {
            long value = input[hpref_offset + hospital * r + slot];
            if (slot < (usz)hospital_length[hospital]) {
                if (value < 0 || value >= r64 || seen[(usz)value]) return -1;
                seen[(usz)value] = true;
                hospital_rank[hospital][(usz)value] = (long)slot;
            } else if (value != -1) return -1;
        }
    }
    for (usz resident = 0; resident < r; resident += 1) {
        for (usz hospital = 0; hospital < h; hospital += 1) {
            bool accepts = false;
            for (usz slot = 0; slot < (usz)resident_length[resident]; slot += 1)
                if (resident_pref[resident][slot] == (long)hospital) accepts = true;
            if (accepts != (hospital_rank[hospital][resident] >= 0)) return -1;
        }
    }
    usz output_bytes = 8 * r;
    if (output == null || capacity < output_bytes) return -2;
    while (true) {
        usz proposer = r;
        for (usz resident = 0; resident < r; resident += 1)
            if (assignment[resident] == -1 && next_choice[resident] < resident_length[resident]) { proposer = resident; break; }
        if (proposer == r) break;
        usz hospital = (usz)resident_pref[proposer][(usz)next_choice[proposer]];
        next_choice[proposer] += 1;
        if (occupancy[hospital] < capacities[hospital]) {
            assignment[proposer] = (long)hospital;
            occupancy[hospital] += 1;
            continue;
        }
        usz worst = r;
        for (usz resident = 0; resident < r; resident += 1)
            if (assignment[resident] == (long)hospital &&
                (worst == r || hospital_rank[hospital][resident] > hospital_rank[hospital][worst])) worst = resident;
        if (worst == r) return -1;
        if (hospital_rank[hospital][proposer] < hospital_rank[hospital][worst]) {
            assignment[worst] = -1;
            assignment[proposer] = (long)hospital;
        }
    }
    char[MAX_OUTPUT] staged = zeroed;
    for (usz resident = 0; resident < r; resident += 1) put64(&staged[0], 8 * resident, assignment[resident]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
