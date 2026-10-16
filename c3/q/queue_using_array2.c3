module queue_using_array2;

const usz MAX_Q = 256, MAX_INPUT = 513;
const long MAX_Q_VALUE = 256;
const long VALUE_LIMIT = 1000000L;
const long VALUE_OFFSET = 1000001L;
const long HASH_MULTIPLIER = 1000003L;
const long HASH_MODULUS = 1000000007L;

fn long queue_using_array2(long* packed, usz length) @export("queue_using_array2") {
    if (packed == null || length < 1 || length > MAX_INPUT) return -1;
    long qv = packed[0];
    if (qv < 0 || qv > MAX_Q_VALUE || length != 1 + (usz)qv * 2) return -1;
    usz q = (usz)qv;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 1) { if (value < -VALUE_LIMIT || value > VALUE_LIMIT) return -1; }
        else if (op == 2 || op == 3) { if (value != 0) return -1; }
        else return -1;
    }

    long[10] values = zeroed;
    usz count = 0;
    long hash = 0;
    for (usz i = 0; i < q; i++) {
        long op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 1) {
            if (count < 10) { values[count] = value; count++; }
        } else if (op == 2 && count > 0) {
            for (usz j = 1; j < count; j++) values[j - 1] = values[j];
            count--;
        }

        hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS;
        hash = (hash * HASH_MULTIPLIER + (long)count) % HASH_MODULUS;
        for (usz j = 0; j < count; j++)
            hash = (hash * HASH_MULTIPLIER + values[j] + VALUE_OFFSET) % HASH_MODULUS;
    }
    return hash;
}
