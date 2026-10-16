module look_scheduling;

const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_i64(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (uint shift = 0; shift < 64; shift += 8) hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    return hash;
}

fn long look_scheduling(long* input, usz length) @export("look_scheduling") {
    if (input == null || length < 4 || length > 4100) return -1;
    long max_track64 = input[0], start64 = input[1], direction = input[2], count64 = input[3];
    if (max_track64 < 1 || max_track64 > 256 || start64 < 0 || start64 >= max_track64 ||
        (direction != 0 && direction != 1) || count64 < 0 || count64 > 4096 || length != (usz)count64 + 4) return -1;
    usz max_track = (usz)max_track64, start = (usz)start64, count = (usz)count64;
    usz[256] lower_counts;
    usz[256] upper_counts;
    for (usz i = 0; i < 256; i++) { lower_counts[i] = 0; upper_counts[i] = 0; }
    long farthest = 0;
    for (usz i = 0; i < count; i++) {
        long request = input[4 + i];
        if (request < -2147483648 || request > 2147483647) return -1;
        if (request >= 0 && request < max_track64) {
            usz track = (usz)request;
            if (track < start) lower_counts[track]++;
            else upper_counts[track]++;
            if (request > farthest) farthest = request;
        }
    }
    long[4096] route;
    usz route_count = 0;
    if (direction == 1) {
        for (usz track = start; track < max_track; track++)
            for (usz repeat = 0; repeat < upper_counts[track]; repeat++) route[route_count++] = (long)track;
        usz track = start;
        while (track > 0) {
            track--;
            for (usz repeat = 0; repeat < lower_counts[track]; repeat++) route[route_count++] = (long)track;
        }
    } else {
        usz track = start;
        while (track > 0) {
            track--;
            for (usz repeat = 0; repeat < lower_counts[track]; repeat++) route[route_count++] = (long)track;
        }
        for (track = start; track < max_track; track++)
            for (usz repeat = 0; repeat < upper_counts[track]; repeat++) route[route_count++] = (long)track;
    }
    ulong hash = hash_i64(FNV_OFFSET, (long)route_count);
    for (usz i = 0; i < route_count; i++) hash = hash_i64(hash, route[i]);
    hash = hash_i64(hash, direction == 1 ? 0 : 1);
    hash = hash_i64(hash, farthest);
    hash = hash_i64(hash, start64);
    return (long)(hash & 0x7fffffffffffffff);
}
