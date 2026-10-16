module jarvis_scan;

const usz MAX_POINTS = 64;
const long MIN_COORDINATE = -10000;
const long MAX_COORDINATE = 10000;

fn long orientation(long ax, long ay, long bx, long by, long cx, long cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

// Return an integer Jarvis-scan hull in counter-clockwise order.
fn long jarvis_scan(long* input, usz length, char* output, usz capacity) @export("jarvis_scan") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > (long)MAX_POINTS) return -1;
    usz count = (usz)input[0];
    if (length != 1 + 2 * count) return -1;

    long[MAX_POINTS] x;
    long[MAX_POINTS] y;
    for (usz point = 0; point < count; point++) {
        x[point] = input[1 + 2 * point];
        y[point] = input[2 + 2 * point];
        if (x[point] < MIN_COORDINATE || x[point] > MAX_COORDINATE ||
            y[point] < MIN_COORDINATE || y[point] > MAX_COORDINATE) return -1;
    }
    if (count <= 2) return 0;
    for (usz first = 0; first < count; first++) {
        for (usz second = first + 1; second < count; second++) {
            if (x[first] == x[second] && y[first] == y[second]) return -1;
        }
    }
    for (usz first = 0; first + 2 < count; first++) {
        for (usz second = first + 1; second + 1 < count; second++) {
            for (usz third = second + 1; third < count; third++) {
                if (orientation(x[first], y[first], x[second], y[second], x[third], y[third]) == 0) return -1;
            }
        }
    }

    usz start = 0;
    for (usz point = 1; point < count; point++) {
        if (x[point] < x[start] || (x[point] == x[start] && y[point] < y[start])) start = point;
    }
    usz[MAX_POINTS] hull;
    usz hull_count = 0;
    usz current = start;
    while (true) {
        if (hull_count == count) return -1;
        hull[hull_count] = current;
        hull_count++;
        usz candidate = (current + 1) % count;
        for (usz point = 0; point < count; point++) {
            if (orientation(x[current], y[current], x[point], y[point], x[candidate], y[candidate]) > 0) candidate = point;
        }
        if (candidate == start) break;
        current = candidate;
    }
    usz bytes = hull_count * 16;
    if (output == null || capacity < bytes) return -2;
    for (usz index = 0; index < hull_count; index++) {
        put_i64(output, index * 16, x[hull[index]]);
        put_i64(output, index * 16 + 8, y[hull[index]]);
    }
    return (long)bytes;
}
