module ear_clipping_polygon_triangulation;

const usz MAX_VERTICES = 64;

long orient(long* v, usz a, usz b, usz c) {
    long abx = v[2 * b] - v[2 * a];
    long aby = v[2 * b + 1] - v[2 * a + 1];
    long acx = v[2 * c] - v[2 * a];
    long acy = v[2 * c + 1] - v[2 * a + 1];
    return abx * acy - aby * acx;
}

bool on_segment(long* v, usz a, usz b, usz p) {
    return v[2 * p] >= (v[2 * a] < v[2 * b] ? v[2 * a] : v[2 * b]) &&
           v[2 * p] <= (v[2 * a] > v[2 * b] ? v[2 * a] : v[2 * b]) &&
           v[2 * p + 1] >= (v[2 * a + 1] < v[2 * b + 1] ? v[2 * a + 1] : v[2 * b + 1]) &&
           v[2 * p + 1] <= (v[2 * a + 1] > v[2 * b + 1] ? v[2 * a + 1] : v[2 * b + 1]);
}

bool segments_intersect(long* v, usz a, usz b, usz c, usz d) {
    long o1 = orient(v, a, b, c), o2 = orient(v, a, b, d);
    long o3 = orient(v, c, d, a), o4 = orient(v, c, d, b);
    if (((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) &&
        ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0))) return true;
    return (o1 == 0 && on_segment(v, a, b, c)) ||
           (o2 == 0 && on_segment(v, a, b, d)) ||
           (o3 == 0 && on_segment(v, c, d, a)) ||
           (o4 == 0 && on_segment(v, c, d, b));
}

bool in_triangle(long* v, usz a, usz b, usz c, usz p, long winding) {
    return orient(v, a, b, p) * winding >= 0 &&
           orient(v, b, c, p) * winding >= 0 &&
           orient(v, c, a, p) * winding >= 0;
}

void write_index(char* output, usz position, usz id) {
    u32 value = (u32)id;
    for (usz byte = 0; byte < 4; byte++) output[4 * position + byte] = (char)(value >> (8 * byte));
}

fn long ear_clipping_polygon_triangulation(long* values, usz length, char* output,
        usz output_capacity) @export("ear_clipping_polygon_triangulation") {
    if (length % 2 != 0 || length / 2 < 3 || length / 2 > MAX_VERTICES || values == null) return -1;
    usz n = length / 2;
    long area2 = 0;
    for (usz i = 0; i < n; i++) {
        usz next = (i + 1) % n;
        long x = values[2 * i], y = values[2 * i + 1];
        if (x < -10000 || x > 10000 || y < -10000 || y > 10000) return -1;
        for (usz j = 0; j < i; j++)
            if (values[2 * i] == values[2 * j] && values[2 * i + 1] == values[2 * j + 1]) return -1;
        area2 += values[2 * i] * values[2 * next + 1] - values[2 * i + 1] * values[2 * next];
        if (orient(values, (i + n - 1) % n, i, next) == 0) return -1;
    }
    if (area2 == 0) return -1;
    for (usz i = 0; i < n; i++) {
        usz inext = (i + 1) % n;
        for (usz j = i + 1; j < n; j++) {
            usz jnext = (j + 1) % n;
            if (inext == j || jnext == i) continue;
            if (segments_intersect(values, i, inext, j, jnext)) return -1;
        }
    }
    if (output == null || output_capacity < 12 * (n - 2)) return -2;

    long winding = area2 > 0 ? 1 : -1;
    bool live[MAX_VERTICES] = zeroed;
    for (usz i = 0; i < n; i++) live[i] = true;
    usz live_count = n, emitted = 0;
    while (live_count > 3) {
        bool clipped = false;
        for (usz current = 0; current < n; current++) {
            if (!live[current]) continue;
            usz prev = (current + n - 1) % n, next = (current + 1) % n;
            while (!live[prev]) prev = (prev + n - 1) % n;
            while (!live[next]) next = (next + 1) % n;
            if (orient(values, prev, current, next) * winding <= 0) continue;
            bool contains = false;
            for (usz point = 0; point < n; point++) {
                if (live[point] && point != prev && point != current && point != next &&
                    in_triangle(values, prev, current, next, point, winding)) {
                    contains = true;
                    break;
                }
            }
            if (contains) continue;
            write_index(output, emitted++, prev);
            write_index(output, emitted++, current);
            write_index(output, emitted++, next);
            live[current] = false;
            live_count--;
            clipped = true;
            break;
        }
        if (!clipped) return -1;
    }
    usz first = 0;
    while (!live[first]) first++;
    usz second = (first + 1) % n;
    while (!live[second]) second = (second + 1) % n;
    usz third = (second + 1) % n;
    while (!live[third]) third = (third + 1) % n;
    write_index(output, emitted++, first);
    write_index(output, emitted++, second);
    write_index(output, emitted++, third);
    return (long)(n - 2);
}
