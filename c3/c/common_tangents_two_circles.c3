module common_tangents_two_circles;

const int MAX_COORDINATE = 100000;
const int MAX_RADIUS = 100000;
const int INPUT_LENGTH = 6;

fn long count_tangents(long x1, long y1, long r1, long x2, long y2, long r2) {
    long dx = x2 - x1;
    long dy = y2 - y1;
    long distance_squared = dx * dx + dy * dy;
    int[2] signs = {-1, 1};
    long candidates = 0;
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            long difference = signs[j] * r2 - signs[i] * r1;
            if (distance_squared >= difference * difference) candidates++;
        }
    }
    if (r1 == 0 && r2 == 0) return 1;
    if (r1 == 0 || r2 == 0) {
        long radius = r1 + r2;
        if (distance_squared == radius * radius) return 1;
        return candidates / 2;
    }
    long radius_sum = r1 + r2;
    long radius_difference = r1 - r2;
    if (distance_squared == radius_sum * radius_sum ||
        distance_squared == radius_difference * radius_difference) candidates--;
    return candidates;
}

fn long common_tangents_two_circles(long* input, usz length) @export("common_tangents_two_circles") {
    if (input == null || length != INPUT_LENGTH) return -1;
    long x1 = input[0], y1 = input[1], r1 = input[2];
    long x2 = input[3], y2 = input[4], r2 = input[5];
    if (x1 < -MAX_COORDINATE || x1 > MAX_COORDINATE ||
        y1 < -MAX_COORDINATE || y1 > MAX_COORDINATE ||
        x2 < -MAX_COORDINATE || x2 > MAX_COORDINATE ||
        y2 < -MAX_COORDINATE || y2 > MAX_COORDINATE ||
        r1 < 0 || r1 > MAX_RADIUS || r2 < 0 || r2 > MAX_RADIUS ||
        (x1 == x2 && y1 == y2)) return -1;
    return count_tangents(x1, y1, r1, x2, y2, r2);
}
