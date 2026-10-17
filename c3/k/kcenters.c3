module kcenters;

const long MAX_POINTS = 8;
const long MAX_DISTANCE = 1000000;
const long JAVA_INT_MAX = 2147483647;
const long MAX_INPUT_LENGTH = 2 + MAX_POINTS * MAX_POINTS;

fn long kcenters(long* values, usz length) @export("kcenters") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long point_count = values[0], center_count = values[1];
    if (point_count < 1 || point_count > MAX_POINTS || center_count < 1 || center_count > point_count ||
        length != (usz)(2 + point_count * point_count)) return -1;
    for (long row = 0; row < point_count; row++) {
        for (long column = 0; column < point_count; column++) {
            long distance = values[2 + row * point_count + column];
            if (distance < 0 || distance > MAX_DISTANCE || (row == column && distance != 0) ||
                distance != values[2 + column * point_count + row]) return -1;
        }
    }

    bool[MAX_POINTS] selected = {false};
    long[MAX_POINTS] max_distance;
    for (long point = 0; point < point_count; point++) max_distance[point] = JAVA_INT_MAX;
    selected[0] = true;
    for (long point = 1; point < point_count; point++) {
        long distance = values[2 + point];
        if (distance < max_distance[point]) max_distance[point] = distance;
    }
    for (long center = 1; center < center_count; center++) {
        long farthest = -1;
        for (long point = 0; point < point_count; point++)
            if (!selected[point] && (farthest == -1 || max_distance[point] > max_distance[farthest])) farthest = point;
        selected[farthest] = true;
        for (long point = 0; point < point_count; point++) {
            long distance = values[2 + farthest * point_count + point];
            if (distance < max_distance[point]) max_distance[point] = distance;
        }
    }
    long result = 0;
    for (long point = 0; point < point_count; point++)
        if (max_distance[point] > result) result = max_distance[point];
    return result;
}
