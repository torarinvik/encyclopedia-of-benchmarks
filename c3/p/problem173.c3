module problem173;

const long MAX_TILES = 1000000;

fn long problem173_ceil_sqrt(long value) {
    if (value <= 0) return 0;
    long root = value;
    long next = (root + value / root) / 2;
    while (next < root) {
        root = next;
        next = (root + value / root) / 2;
    }
    return root * root == value ? root : root + 1;
}

fn long problem173(long max_tiles) @export("problem173") {
    if (max_tiles < 0 || max_tiles > MAX_TILES) return -1;
    long answer = 0;
    for (long outer_width = 3; outer_width < max_tiles / 4 + 2; outer_width++) {
        long hole_width = 1;
        long outer_area = outer_width * outer_width;
        if (outer_area > max_tiles) {
            hole_width = problem173_ceil_sqrt(outer_area - max_tiles);
            if (hole_width < 1) hole_width = 1;
        }
        if ((outer_width - hole_width) % 2 != 0) hole_width++;
        answer += (outer_width - hole_width - 2) / 2 + 1;
    }
    return answer;
}
