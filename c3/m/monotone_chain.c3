module monotone_chain;

const usz MAX_POINT_COUNT = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = 130;
const long MAX_COORDINATE = 1000000;

struct Point { int x; int y; }

fn bool point_less(Point a, Point b) {
    return a.x < b.x || (a.x == b.x && a.y < b.y);
}

fn long cross_product(Point origin, Point first, Point second) {
    long dx1 = (long)first.x - (long)origin.x;
    long dy1 = (long)first.y - (long)origin.y;
    long dx2 = (long)second.x - (long)origin.x;
    long dy2 = (long)second.y - (long)origin.y;
    return dx1 * dy2 - dy1 * dx2;
}

fn void store_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long monotone_chain(long* values, usz length, char* output, usz capacity)
    @export("monotone_chain") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_count = values[0];
    if (raw_count < 0 || raw_count > (long)MAX_POINT_COUNT) return -1;
    usz count = (usz)raw_count;
    if (length != 1 + 2 * count) return -1;

    Point[64] points = {};
    Point[64] scratch;
    Point[128] hull;
    for (usz index = 0; index < count; index += 1) {
        long x = values[1 + 2 * index], y = values[2 + 2 * index];
        if (x < -MAX_COORDINATE || x > MAX_COORDINATE ||
            y < -MAX_COORDINATE || y > MAX_COORDINATE) return -1;
        points[index].x = (int)x;
        points[index].y = (int)y;
    }

    for (usz width = 1; width < count; width *= 2) {
        for (usz start = 0; start < count; start += 2 * width) {
            usz middle = start + width;
            if (middle > count) middle = count;
            usz end = middle + width;
            if (end > count) end = count;
            usz left = start, right = middle, destination = start;
            while (left < middle && right < end) {
                if (point_less(points[right], points[left])) scratch[destination++] = points[right++];
                else scratch[destination++] = points[left++];
            }
            while (left < middle) scratch[destination++] = points[left++];
            while (right < end) scratch[destination++] = points[right++];
        }
        for (usz index = 0; index < count; index += 1) points[index] = scratch[index];
    }

    usz unique_count = 0;
    for (usz index = 0; index < count; index += 1) {
        if (unique_count == 0 || points[index].x != points[unique_count - 1].x ||
            points[index].y != points[unique_count - 1].y)
            points[unique_count++] = points[index];
    }

    usz hull_count = 0;
    if (unique_count == 1) hull[hull_count++] = points[0];
    else if (unique_count > 1) {
        for (usz index = 0; index < unique_count; index += 1) {
            while (hull_count >= 2 &&
                   cross_product(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                hull_count -= 1;
            hull[hull_count++] = points[index];
        }
        usz lower_count = hull_count;
        for (usz index = unique_count - 1; index > 0;) {
            index -= 1;
            while (hull_count > lower_count &&
                   cross_product(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0)
                hull_count -= 1;
            hull[hull_count++] = points[index];
        }
        hull_count -= 1;
    }

    usz byte_count = 8 * hull_count;
    if (output == null || capacity < byte_count) return -2;
    for (usz index = 0; index < hull_count; index += 1) {
        store_i32_le(output, 8 * index, hull[index].x);
        store_i32_le(output, 8 * index + 4, hull[index].y);
    }
    return (long)byte_count;
}
