module polygon_area_centroid;

const usz MAX_VERTICES = 16;
const usz MAX_PARSEABLE_LENGTH = 34;
const long OUTPUT_SCALE = 1000000;

fn void store_i64(char* output, usz offset, long value) {
    ulong bits = bitcast(value, ulong);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long rounded_micro(long numerator, long denominator) {
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    long sign = numerator < 0 ? -1 : 1;
    ulong magnitude = (ulong)(numerator < 0 ? -numerator : numerator);
    ulong scaled = magnitude * (ulong)OUTPUT_SCALE;
    ulong divisor = (ulong)denominator;
    ulong quotient = scaled / divisor;
    ulong remainder = scaled % divisor;
    if (2 * remainder >= divisor) quotient++;
    return sign * (long)quotient;
}

fn long polygon_area_centroid(long* input, usz length, char* output, usz capacity) @export("polygon_area_centroid") {
    if (input == null || length < 7 || length > MAX_PARSEABLE_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 3 || count_value > (long)MAX_VERTICES) return -1;
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) return -1;
    long[MAX_VERTICES] xs;
    long[MAX_VERTICES] ys;
    for (usz i = 0; i < count; i++) {
        long x = input[1 + 2 * i];
        long y = input[2 + 2 * i];
        if (x < -50 || x > 50 || y < -50 || y > 50) return -1;
        for (usz j = 0; j < i; j++) if (xs[j] == x && ys[j] == y) return -1;
        xs[i] = x; ys[i] = y;
    }
    long twice_area = 0;
    for (usz i = 0; i < count; i++) {
        usz next = (i + 1) % count;
        twice_area += xs[i] * ys[next] - xs[next] * ys[i];
    }
    if (twice_area == 0) return -1;
    long orientation = twice_area > 0 ? 1 : -1;
    for (usz i = 0; i < count; i++) {
        usz next = (i + 1) % count;
        for (usz j = 0; j < count; j++) {
            if (j == i || j == next) continue;
            long side = (xs[next] - xs[i]) * (ys[j] - ys[i]) - (ys[next] - ys[i]) * (xs[j] - xs[i]);
            if (side * orientation <= 0) return -1;
        }
    }
    long numerator_x = 0;
    long numerator_y = 0;
    for (usz i = 0; i < count; i++) {
        usz next = (i + 1) % count;
        long cross = xs[i] * ys[next] - xs[next] * ys[i];
        numerator_x += (xs[i] + xs[next]) * cross;
        numerator_y += (ys[i] + ys[next]) * cross;
    }
    long x_micro = rounded_micro(numerator_x, 3 * twice_area);
    long y_micro = rounded_micro(numerator_y, 3 * twice_area);
    if (output == null || capacity < 16) return -2;
    store_i64(output, 0, x_micro);
    store_i64(output, 8, y_micro);
    return 16;
}
