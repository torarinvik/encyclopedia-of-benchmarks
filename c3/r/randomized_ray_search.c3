module randomized_ray_search;

const usz MAX_RAYS = 5;
const usz MAX_ROUNDS = 32;
const usz MAX_INPUT = 11;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long randomized_ray_search(long* input, usz length, char* output,
        usz capacity) @export("randomized_ray_search") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long ray_count_value = input[0], growth = input[1], initial = input[2];
    if (ray_count_value < 2 || ray_count_value > (long)MAX_RAYS ||
        growth < 2 || growth > 4 || initial < 1000 || initial >= growth * 1000 ||
        length != (usz)ray_count_value + 5) return -1;
    usz ray_count = (usz)ray_count_value;
    usz[MAX_RAYS] permutation = zeroed;
    bool[MAX_RAYS] seen = zeroed;
    for (usz index = 0; index < ray_count; index += 1) {
        long ray_value = input[3 + index];
        if (ray_value < 0 || ray_value >= ray_count_value) return -1;
        usz ray = (usz)ray_value;
        if (seen[ray]) return -1;
        seen[ray] = true;
        permutation[index] = ray;
    }
    long target_ray = input[3 + ray_count], target_distance = input[4 + ray_count];
    if (target_ray < 0 || target_ray >= ray_count_value ||
        target_distance < 1 || target_distance > 1000000000) return -1;

    long distance = initial, total = 0, attempts = 0;
    bool found = false;
    for (usz round = 0; round < MAX_ROUNDS; round += 1) {
        usz ray = permutation[round % ray_count];
        attempts += 1;
        if ((long)ray == target_ray && target_distance <= distance) {
            total += target_distance;
            found = true;
            break;
        }
        total += 2 * distance;
        distance *= growth;
    }
    if (!found) return -1;
    if (output == null || capacity < 16) return -2;
    char[16] staged = zeroed;
    store_i64_le(&staged[0], 0, attempts);
    store_i64_le(&staged[0], 8, total);
    for (usz byte = 0; byte < 16; byte += 1) output[byte] = staged[byte];
    return 16;
}
