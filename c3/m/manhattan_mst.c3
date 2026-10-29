module manhattan_mst;

const usz MAX_POINTS = 32;
const usz MAX_INPUT_LENGTH = 65;
const long COORDINATE_LIMIT = 1000000;

fn long manhattan_mst(long* values, usz length) @export("manhattan_mst") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    if (count_value < 1 || count_value > (long)MAX_POINTS) return -1;
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) return -1;

    long[MAX_POINTS] x;
    long[MAX_POINTS] y;
    for (usz point = 0; point < count; point++) {
        x[point] = values[1 + 2 * point];
        y[point] = values[2 + 2 * point];
        if (x[point] < -COORDINATE_LIMIT || x[point] > COORDINATE_LIMIT ||
            y[point] < -COORDINATE_LIMIT || y[point] > COORDINATE_LIMIT) return -1;
    }

    bool[MAX_POINTS] in_tree;
    bool[MAX_POINTS] has_best;
    long[MAX_POINTS] best;
    for (usz point = 0; point < MAX_POINTS; point++) {
        in_tree[point] = false;
        has_best[point] = false;
        best[point] = 0;
    }
    has_best[0] = true;
    long total = 0;
    for (usz step = 0; step < count; step++) {
        usz selected = count;
        for (usz point = 0; point < count; point++) {
            if (!in_tree[point] && has_best[point] &&
                (selected == count || best[point] < best[selected])) selected = point;
        }
        if (selected == count) return -1;
        in_tree[selected] = true;
        total += best[selected];
        for (usz point = 0; point < count; point++) {
            if (in_tree[point]) continue;
            long dx = x[selected] - x[point];
            long dy = y[selected] - y[point];
            if (dx < 0) dx = -dx;
            if (dy < 0) dy = -dy;
            long distance = dx + dy;
            if (!has_best[point] || distance < best[point]) {
                has_best[point] = true;
                best[point] = distance;
            }
        }
    }
    return total;
}
