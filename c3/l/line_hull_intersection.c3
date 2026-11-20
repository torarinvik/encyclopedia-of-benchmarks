module line_hull_intersection;

const usz MAX_VERTICES = 16;
const usz MAX_PARSEABLE_LENGTH = 38;

fn int polar_half(long x, long y) {
    return (y > 0 || (y == 0 && x >= 0)) ? 0 : 1;
}
fn bool angle_before(long ax, long ay, long bx, long by) {
    int ah = polar_half(ax, ay), bh = polar_half(bx, by);
    if (ah != bh) return ah < bh;
    return ax * by - ay * bx > 0;
}
fn usz rotation_minimum(long* ex, long* ey, usz count) {
    usz low = 0, high = count - 1;
    while (low < high) {
        usz middle = (low + high) / 2;
        if (angle_before(ex[middle], ey[middle], ex[high], ey[high])) high = middle;
        else low = middle + 1;
    }
    return low;
}
fn usz support_edge(long* ex, long* ey, usz count, long tx, long ty) {
    usz pivot = rotation_minimum(ex, ey, count);
    usz low = 0, high = count;
    while (low < high) {
        usz middle = (low + high) / 2;
        usz index = (pivot + middle) % count;
        if (angle_before(ex[index], ey[index], tx, ty)) low = middle + 1;
        else high = middle;
    }
    return (pivot + low) % count;
}
fn long line_value(long* xs, long* ys, usz index, long ox, long oy, long dx, long dy) {
    return dx * (ys[index] - oy) - dy * (xs[index] - ox);
}
fn long line_parameter(long* xs, long* ys, usz index, long ox, long oy, long dx, long dy) {
    return (xs[index] - ox) * dx + (ys[index] - oy) * dy;
}
fn void crossing(long* xs, long* ys, usz count, long ox, long oy, long dx, long dy,
                 usz start, usz end, bool increasing, long* hit) {
    usz span = (end + count - start) % count;
    usz low = 0, high = span;
    while (high - low > 1) {
        usz middle = (low + high) / 2;
        usz index = (start + middle) % count;
        long value = line_value(xs, ys, index, ox, oy, dx, dy);
        if (increasing ? value < 0 : value > 0) low = middle;
        else high = middle;
    }
    usz index = (start + low) % count;
    if (line_value(xs, ys, (start + high) % count, ox, oy, dx, dy) == 0)
        index = (start + high) % count;
    long value = line_value(xs, ys, index, ox, oy, dx, dy);
    if (value == 0) {
        hit[0] = (long)index;
        hit[1] = line_parameter(xs, ys, index, ox, oy, dx, dy);
        hit[2] = 1;
        return;
    }
    usz next = (index + 1) % count;
    long next_value = line_value(xs, ys, next, ox, oy, dx, dy);
    long denominator = value - next_value;
    long edge_dot = (xs[next] - xs[index]) * dx + (ys[next] - ys[index]) * dy;
    long numerator = line_parameter(xs, ys, index, ox, oy, dx, dy) * denominator + value * edge_dot;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    hit[0] = (long)index; hit[1] = numerator; hit[2] = denominator;
}
fn void store_i64(char* output, usz offset, long value) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long line_hull_intersection(long* input, usz length, char* output, usz capacity)
    @export("line_hull_intersection") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 3 || count_value > (long)MAX_VERTICES) return -1;
    usz count = (usz)count_value;
    if (length != 5 + 2 * count) return -1;
    long ox = input[1], oy = input[2], x2 = input[3], y2 = input[4];
    if (ox < -50 || ox > 50 || oy < -50 || oy > 50 || x2 < -50 || x2 > 50 || y2 < -50 || y2 > 50) return -1;
    long dx = x2 - ox, dy = y2 - oy;
    if (dx == 0 && dy == 0) return -1;

    long[MAX_VERTICES] xs, ys, ex, ey;
    for (usz i = 0; i < count; i++) {
        xs[i] = input[5 + 2 * i]; ys[i] = input[6 + 2 * i];
        if (xs[i] < -50 || xs[i] > 50 || ys[i] < -50 || ys[i] > 50) return -1;
        for (usz j = 0; j < i; j++) if (xs[j] == xs[i] && ys[j] == ys[i]) return -1;
    }
    long area2 = 0;
    for (usz i = 0; i < count; i++) {
        usz next = (i + 1) % count;
        ex[i] = xs[next] - xs[i]; ey[i] = ys[next] - ys[i];
        area2 += xs[i] * ys[next] - xs[next] * ys[i];
    }
    if (area2 <= 0) return -1;
    for (usz i = 0; i < count; i++) {
        usz next = (i + 1) % count;
        for (usz j = 0; j < count; j++) {
            if (j == i || j == next) continue;
            long side = ex[i] * (ys[j] - ys[i]) - ey[i] * (xs[j] - xs[i]);
            if (side <= 0) return -1;
        }
    }
    usz maximum = support_edge(ex, ey, count, -dx, -dy);
    usz minimum = support_edge(ex, ey, count, dx, dy);
    long max_value = line_value(xs, ys, maximum, ox, oy, dx, dy);
    long min_value = line_value(xs, ys, minimum, ox, oy, dx, dy);
    long first = -1, second = -1;
    if (min_value > 0 || max_value < 0) {
        first = second = -1;
    } else if (min_value == 0 || max_value == 0) {
        usz touch = min_value == 0 ? minimum : maximum;
        usz next = (touch + 1) % count, previous = (touch + count - 1) % count;
        if (line_value(xs, ys, touch, ox, oy, dx, dy) == 0 && line_value(xs, ys, next, ox, oy, dx, dy) == 0)
            first = second = (long)touch;
        else if (line_value(xs, ys, previous, ox, oy, dx, dy) == 0 && line_value(xs, ys, touch, ox, oy, dx, dy) == 0)
            first = second = (long)previous;
        else { first = (long)touch; second = -1; }
    } else {
        long[MAX_VERTICES] h1, h2;
        crossing(xs, ys, count, ox, oy, dx, dy, maximum, minimum, false, h1);
        crossing(xs, ys, count, ox, oy, dx, dy, minimum, maximum, true, h2);
        if (h1[1] * h2[2] <= h2[1] * h1[2]) { first = h1[0]; second = h2[0]; }
        else { first = h2[0]; second = h1[0]; }
    }
    if (output == null || capacity < 16) return -2;
    store_i64(output, 0, first); store_i64(output, 8, second);
    return 16;
}
