module shootout_hash;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* ptr);

const long MAX_N = 3500000;
const uint[28] BUCKET_PRIMES = {
    53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
    49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
    6291469, 12582917, 25165843, 50331653, 100663319, 201326611,
    402653189, 805306457, 1610612741, 3221225473, 4294967291
};

fn usz bucket_count_for(uint n) {
    usz index = 0;
    while (BUCKET_PRIMES[index] < n) index++;
    return BUCKET_PRIMES[index].usz();
}

fn usz hash_key(uint value, uint base, usz bucket_count) {
    char[16] reverse;
    usz length = 0;
    do {
        uint digit = value % base;
        reverse[length++] = (char)(digit < 10 ? 48 + digit : 87 + digit);
        value /= base;
    } while (value != 0);
    ulong hash = 0;
    while (length != 0) {
        length--;
        hash = 5 * hash + reverse[length].u8();
    }
    return (hash % bucket_count).usz();
}

fn bool hex_key_matches_decimal(uint hex_value, uint decimal_value) {
    while (hex_value != 0 && decimal_value != 0) {
        uint digit = hex_value & 15;
        if (digit >= 10 || digit != decimal_value % 10) return false;
        hex_value >>= 4;
        decimal_value /= 10;
    }
    return hex_value == 0 && decimal_value == 0;
}

fn long shootout_hash(long n) @export("shootout_hash") {
    if (n < 0 || n > MAX_N) return -1;
    uint bound = n.uint();
    usz bucket_count = bucket_count_for(bound);
    uint* heads = (uint*)calloc(bucket_count, sizeof(uint));
    uint* next = (uint*)calloc((bound + 1).usz(), sizeof(uint));
    if (heads == null || next == null) {
        free(heads);
        free(next);
        return -1;
    }

    for (uint value = 1; value <= bound; value++) {
        usz bucket = hash_key(value, 16, bucket_count);
        uint node = heads[bucket];
        uint previous = 0;
        while (node != 0) {
            if (node == value) break;
            previous = node;
            node = next[node.usz()];
        }
        if (node == 0) {
            if (previous == 0) heads[bucket] = value;
            else next[previous.usz()] = value;
        }
    }

    long found = 0;
    uint value = bound;
    while (value > 0) {
        usz bucket = hash_key(value, 10, bucket_count);
        uint node = heads[bucket];
        while (node != 0) {
            if (hex_key_matches_decimal(node, value)) {
                found++;
                break;
            }
            node = next[node.usz()];
        }
        value--;
    }
    free(heads);
    free(next);
    return found;
}
