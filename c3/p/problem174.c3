module problem174;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long MAX_TILES = 1000000;

fn long problem174_ceil_sqrt(long value) {
    if (value <= 0) return 0;
    long root = value;
    long next = (root + value / root) / 2;
    while (next < root) {
        root = next;
        next = (root + value / root) / 2;
    }
    return root * root == value ? root : root + 1;
}

fn long problem174(long t_limit, long n_limit) @export("problem174") {
    if (t_limit > MAX_TILES) return -1;
    if (t_limit < 0) return 0;
    u8* count = (u8*)calloc((usz)t_limit + 1, sizeof(u8));
    if (count == null) return -1;
    defer free(count);
    for (long outer_width = 3; outer_width < t_limit / 4 + 2; outer_width++) {
        long outer_area = outer_width * outer_width;
        long hole_lower = 1;
        if (outer_area > t_limit) {
            hole_lower = problem174_ceil_sqrt(outer_area - t_limit);
            if (hole_lower < 1) hole_lower = 1;
        }
        if ((outer_width - hole_lower) % 2 != 0) hole_lower++;
        for (long hole_width = hole_lower; hole_width < outer_width - 1; hole_width += 2) {
            long tiles = outer_area - hole_width * hole_width;
            count[(usz)tiles]++;
        }
    }
    long answer = 0;
    for (usz tiles = 1; tiles <= (usz)t_limit; tiles++)
        if (count[tiles] >= 1 && count[tiles] <= n_limit) answer++;
    return answer;
}
