module ring_buffer;

const usz MAX_Q = 256, MAX_INPUT = 513;
const long VALUE_LIMIT = 1000000L;
const long VALUE_OFFSET = 1000001L;
const long HASH_MULTIPLIER = 1000003L;
const long HASH_MODULUS = 1000000007L;

fn long ring_buffer(long* packed, usz length) @export("ring_buffer") {
    if (packed == null || length < 1 || length > MAX_INPUT) return -1;
    long qv = packed[0];
    if (qv < 0 || qv > 256 || length != 1 + (usz)qv * 2) return -1;
    usz q = (usz)qv;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 2], payload = packed[2 + i * 2];
        if (op == 0) { if (payload < -VALUE_LIMIT || payload > VALUE_LIMIT) return -1; }
        else if (op == 4) { if (payload < 0 || payload > VALUE_LIMIT) return -1; }
        else if (op >= 1 && op <= 3) { if (payload != 0) return -1; }
        else if (op >= 5 && op <= 9) { if (payload != 0) return -1; }
        else return -1;
    }

    long[8] values = zeroed;
    usz head = 0, tail = 0, count = 0;
    long hash = 0;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 2], payload = packed[2 + i * 2];
        long status = 0, result = 0;
        if (op == 0) {
            if (count == 8) status = 1;
            else { values[tail] = payload; tail = (tail + 1) % 8; count++; }
        } else if (op == 1) {
            if (count == 0) status = 2;
            else { result = values[head]; head = (head + 1) % 8; count--; }
        } else if (op == 2) {
            if (count == 0) status = 2;
            else result = values[head];
        } else if (op == 3) {
            if (count == 0) status = 2;
            else result = values[(tail + 7) % 8];
        } else if (op == 4) {
            if (payload >= (long)count) status = 3;
            else result = values[(head + (usz)payload) % 8];
        } else if (op == 5) {
            head = tail = count = 0;
        } else if (op == 6) result = (long)count;
        else if (op == 7) result = 8 - (long)count;
        else if (op == 8) { if (count == 0) result = 1; }
        else { if (count == 8) result = 1; }

        hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + status) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + result + VALUE_OFFSET) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + (long)count) % HASH_MODULUS;
        for (usz j = 0; j < count; j++) {
            usz position = (head + j) % 8;
            hash = (hash * HASH_MULTIPLIER + values[position] + VALUE_OFFSET) % HASH_MODULUS;
        }
    }
    return hash;
}
