module two_pset;

const long HASH_MULTIPLIER = 1000003L;
const long HASH_MODULUS = 1000000007L;

fn long two_pset(long* packed, usz length) @export("two_pset") {
    if (packed == null || length < 1 || length > 1025) return -1;
    long qv = packed[0];
    if (qv < 0 || qv > 256 || length != 1 + (usz)qv * 4) return -1;
    usz q = (usz)qv;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 4], set_id = packed[2 + i * 4];
        long value = packed[3 + i * 4], other_id = packed[4 + i * 4];
        if (op >= 0 && op <= 2) {
            if (set_id < 0 || set_id > 1 || value < 0 || value > 63 || other_id != 0) return -1;
        } else if (op == 3 || op == 4) {
            if (set_id < 0 || set_id > 1 || value != 0 || other_id < 0 || other_id > 1) return -1;
        } else return -1;
    }

    long[128] additions = zeroed;
    long[128] tombstones = zeroed;
    long digest = 0;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 4], set_id = packed[2 + i * 4];
        long value = packed[3 + i * 4], other_id = packed[4 + i * 4];
        usz base = (usz)set_id * 64;
        long result = 0;
        if (op == 0) additions[base + (usz)value] = 1;
        else if (op == 1) {
            usz index = base + (usz)value;
            if (additions[index] != 0 && tombstones[index] == 0) tombstones[index] = 1;
        } else if (op == 2) {
            usz index = base + (usz)value;
            if (additions[index] != 0 && tombstones[index] == 0) result = 1;
        } else if (op == 3) {
            usz other_base = (usz)other_id * 64;
            result = 1;
            for (usz e = 0; e < 64; e++) {
                if ((additions[base + e] != 0 && additions[other_base + e] == 0) ||
                    (tombstones[base + e] != 0 && tombstones[other_base + e] == 0)) result = 0;
            }
        } else {
            usz other_base = (usz)other_id * 64;
            for (usz e = 0; e < 64; e++) {
                if (additions[base + e] != 0 || additions[other_base + e] != 0) additions[base + e] = 1;
                if (tombstones[base + e] != 0 || tombstones[other_base + e] != 0) tombstones[base + e] = 1;
            }
        }
        digest = (digest * HASH_MULTIPLIER + op) % HASH_MODULUS;
        digest = (digest * HASH_MULTIPLIER + result) % HASH_MODULUS;
    }

    for (usz set_id = 0; set_id < 2; set_id++) {
        usz base = set_id * 64;
        for (usz e = 0; e < 64; e++) digest = (digest * HASH_MULTIPLIER + additions[base + e]) % HASH_MODULUS;
        for (usz e = 0; e < 64; e++) digest = (digest * HASH_MULTIPLIER + tombstones[base + e]) % HASH_MODULUS;
    }
    return digest;
}
