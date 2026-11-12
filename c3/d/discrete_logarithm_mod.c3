module discrete_logarithm_mod;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const usz TABLE_SIZE = 65536;
const usz TABLE_MASK = TABLE_SIZE - 1;
const ulong MAX_MODULUS = 1000000000;

fn ulong gcd_u64(ulong left, ulong right) {
    while (right != 0) {
        ulong remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn ulong ceil_sqrt(ulong value) {
    ulong low = 1, high = 31623;
    while (low < high) {
        ulong middle = low + (high - low) / 2;
        if (middle * middle >= value) high = middle;
        else low = middle + 1;
    }
    return low;
}

fn ulong pow_mod(ulong base, ulong exponent, ulong modulus) {
    ulong result = 1 % modulus;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long inverse_mod(ulong value, ulong modulus) {
    long old_r = value.long(), r = modulus.long();
    long old_t = 1, t = 0;
    while (r != 0) {
        long quotient = old_r / r;
        long next_r = old_r - quotient * r;
        long next_t = old_t - quotient * t;
        old_r = r; r = next_r; old_t = t; t = next_t;
    }
    if (old_r != 1) return -1;
    old_t = old_t % modulus.long();
    if (old_t < 0) old_t += modulus.long();
    return old_t;
}

fn void insert_baby(ulong* keys, u32* steps, ulong key, u32 step) {
    usz slot = (key & TABLE_MASK.ulong()).usz();
    while (steps[slot] != 0) {
        if (keys[slot] == key) return;
        slot = (slot + 1) & TABLE_MASK;
    }
    keys[slot] = key;
    steps[slot] = step + 1;
}

fn long find_baby(ulong* keys, u32* steps, ulong key) {
    usz slot = (key & TABLE_MASK.ulong()).usz();
    while (steps[slot] != 0) {
        if (keys[slot] == key) return steps[slot].long() - 1;
        slot = (slot + 1) & TABLE_MASK;
    }
    return -1;
}

fn long coprime_log(ulong x, ulong y, ulong modulus) {
    if (y == 1 % modulus) return 0;
    ulong width = ceil_sqrt(modulus);
    ulong* keys = (ulong*)malloc(TABLE_SIZE * 8);
    u32* steps = (u32*)malloc(TABLE_SIZE * 4);
    if (keys == null || steps == null) {
        free(keys); free(steps);
        return -1;
    }
    defer free(keys);
    defer free(steps);
    for (usz slot = 0; slot < TABLE_SIZE; slot++) steps[slot] = 0;
    ulong residue = 1 % modulus;
    for (ulong step = 0; step < width; step++) {
        insert_baby(keys, steps, residue, step.u32());
        residue = (residue * x) % modulus;
    }
    long inverse = inverse_mod(x, modulus);
    if (inverse < 0) return -1;
    ulong giant_factor = pow_mod(inverse.ulong(), width, modulus);
    ulong giant = y;
    for (ulong block = 0; block * width <= modulus; block++) {
        long baby = find_baby(keys, steps, giant);
        if (baby >= 0) {
            ulong answer = block * width + baby.ulong();
            if (answer <= modulus) return answer.long();
            return -1;
        }
        giant = (giant * giant_factor) % modulus;
    }
    return -1;
}

fn long extended_log(ulong x, ulong initial_y, ulong initial_modulus) {
    ulong y = initial_y, modulus = initial_modulus;
    if (modulus == 1) return 0;
    ulong accumulator = 1, added = 0;
    while (gcd_u64(x, modulus) > 1) {
        ulong divisor = gcd_u64(x, modulus);
        if (y == accumulator) return added.long();
        if (y % divisor != 0) return -1;
        y /= divisor;
        modulus /= divisor;
        accumulator = (accumulator * (x / divisor)) % modulus;
        added += 1;
        if (modulus == 1) return added.long();
    }
    long inverse = inverse_mod(accumulator, modulus);
    if (inverse < 0) return -1;
    ulong target = (y * inverse.ulong()) % modulus;
    long remaining = coprime_log(x % modulus, target, modulus);
    if (remaining < 0) return -1;
    return added.long() + remaining;
}

// Packed input [x, y, m]; return the least nonnegative exponent or -1.
fn long discrete_logarithm_mod(long* values, usz length) @export("discrete_logarithm_mod") {
    if (values == null || length != 3) return -1;
    if (values[0] < 0 || values[1] < 0 || values[2] < 1 ||
        values[2].ulong() > MAX_MODULUS || values[0] >= values[2] || values[1] >= values[2]) return -1;
    return extended_log(values[0].ulong(), values[1].ulong(), values[2].ulong());
}
