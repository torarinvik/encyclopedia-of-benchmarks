module baby_step_giant_step;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const usz TABLE_SIZE = 65536;
const usz TABLE_MASK = TABLE_SIZE - 1;
const ulong MAX_MODULUS = 1000000007;

fn ulong gcd_u64(ulong left, ulong right) {
    while (right != 0) {
        ulong remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn ulong ceil_sqrt(ulong value) {
    ulong low = 1, high = 31624;
    while (low < high) {
        ulong middle = low + (high - low) / 2;
        if (middle * middle >= value) high = middle;
        else low = middle + 1;
    }
    return low;
}

fn void insert_baby(ulong* keys, u32* encoded_steps, ulong key, u32 step) {
    usz slot = (key & TABLE_MASK.ulong()).usz();
    while (encoded_steps[slot] != 0 && keys[slot] != key) slot = (slot + 1) & TABLE_MASK;
    keys[slot] = key;
    encoded_steps[slot] = step + 1;
}

fn long find_baby(ulong* keys, u32* encoded_steps, ulong key) {
    usz slot = (key & TABLE_MASK.ulong()).usz();
    while (encoded_steps[slot] != 0) {
        if (keys[slot] == key) return encoded_steps[slot].long() - 1;
        slot = (slot + 1) & TABLE_MASK;
    }
    return -1;
}

// Packed input [a, b, n]; return the least positive discrete logarithm or -1.
fn long baby_step_giant_step(long* values, usz length) @export("baby_step_giant_step") {
    if (length != 3 || values == null) return -1;
    if (values[0] < 0 || values[1] < 0 || values[2] < 1 ||
        values[2].ulong() > MAX_MODULUS || values[0] >= values[2] || values[1] >= values[2]) return -1;
    ulong a = values[0].ulong(), b = values[1].ulong(), modulus = values[2].ulong();
    if (gcd_u64(a, modulus) != 1) return -1;

    ulong m = ceil_sqrt(modulus);
    ulong* keys = (ulong*)malloc(TABLE_SIZE * 8);
    u32* encoded_steps = (u32*)malloc(TABLE_SIZE * 4);
    if (keys == null || encoded_steps == null) {
        free(keys);
        free(encoded_steps);
        return -1;
    }
    defer free(keys);
    defer free(encoded_steps);
    for (usz index = 0; index < TABLE_SIZE; index++) keys[index] = 0;
    for (usz index = 0; index < TABLE_SIZE; index++) encoded_steps[index] = 0;
    ulong step = 1;
    for (ulong index = 0; index < m; index++) {
        insert_baby(keys, encoded_steps, (step * b) % modulus, index.u32());
        step = (step * a) % modulus;
    }
    ulong giant_step = step;
    for (ulong index = m; index <= modulus; index += m) {
        long baby_index = find_baby(keys, encoded_steps, step);
        if (baby_index >= 0) return index.long() - baby_index;
        step = (step * giant_step) % modulus;
    }
    return -1;
}
