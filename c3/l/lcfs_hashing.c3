module lcfs_hashing;

const usz MAX_CAPACITY = 32;
const usz MAX_INPUT_LENGTH = 35;
const long MAX_KEY = 1000000;

fn long lcfs_hashing(long* input, usz length) @export("lcfs_hashing") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > (long)MAX_CAPACITY
            || count_value < 0 || count_value > capacity_value
            || length != (usz)count_value + 2) return -1;
    usz capacity = (usz)capacity_value, count = (usz)count_value;
    for (usz i = 0; i < count; i++) {
        long key = input[i + 2];
        if (key < 0 || key > MAX_KEY) return -1;
        for (usz j = 0; j < i; j++) if (input[j + 2] == key) return -1;
    }

    long[MAX_CAPACITY] table;
    for (usz i = 0; i < capacity; i++) table[i] = -1;
    long displacements = 0;
    for (usz i = 0; i < count; i++) {
        long incoming = input[i + 2];
        usz slot = (usz)(incoming % capacity_value), probes = 0;
        while (table[slot] != -1) {
            if (probes >= capacity) return -1;
            long resident = table[slot];
            table[slot] = incoming;
            incoming = resident;
            slot = (slot + 1) % capacity;
            probes += 1;
            displacements += 1;
        }
        table[slot] = incoming;
    }
    return displacements;
}
