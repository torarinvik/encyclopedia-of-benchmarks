module rectangle_union_area_sweep;

const usz MAX_EVENTS = 128;
const usz TREE_SIZE = 512;
struct Event { long x; long y1; long y2; long delta; }

fn void sift_values(long* values, usz root_start, usz end_value) {
    usz root = root_start;
    while (root * 2 + 1 < end_value) {
        usz child = root * 2 + 1;
        if (child + 1 < end_value && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) return;
        long value = values[root]; values[root] = values[child]; values[child] = value;
        root = child;
    }
}

fn void sort_values(long* values, usz count) {
    for (usz start = count / 2; start > 0; start--) sift_values(values, start - 1, count);
    for (usz end = count; end > 1; end--) {
        long value = values[0]; values[0] = values[end - 1]; values[end - 1] = value;
        sift_values(values, 0, end - 1);
    }
}

fn void sift_events(Event* events, usz root_start, usz end_value) {
    usz root = root_start;
    while (root * 2 + 1 < end_value) {
        usz child = root * 2 + 1;
        if (child + 1 < end_value && events[child].x < events[child + 1].x) child++;
        if (events[root].x >= events[child].x) return;
        Event value = events[root]; events[root] = events[child]; events[child] = value;
        root = child;
    }
}

fn void sort_events(Event* events, usz count) {
    for (usz start = count / 2; start > 0; start--) sift_events(events, start - 1, count);
    for (usz end = count; end > 1; end--) {
        Event value = events[0]; events[0] = events[end - 1]; events[end - 1] = value;
        sift_events(events, 0, end - 1);
    }
}

fn usz lower_bound(long* values, usz count, long target) {
    usz low = 0, high = count;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (values[middle] < target) low = middle + 1;
        else high = middle;
    }
    return low;
}

fn void update(usz node, usz left, usz right, usz ql, usz qr, long delta,
               long* ys, long* cover, long* covered) {
    if (ql <= left && right <= qr) cover[node] += delta;
    else {
        usz middle = left + (right - left) / 2;
        if (ql < middle) update(node * 2, left, middle, ql, qr, delta, ys, cover, covered);
        if (qr > middle) update(node * 2 + 1, middle, right, ql, qr, delta, ys, cover, covered);
    }
    if (cover[node] > 0) covered[node] = ys[right] - ys[left];
    else if (right - left == 1) covered[node] = 0;
    else covered[node] = covered[node * 2] + covered[node * 2 + 1];
}

fn long rectangle_union_area_sweep(long* input, usz length) @export("rectangle_union_area_sweep") {
    if (input == null || length < 1 || length > 258) return -1;
    if (input[0] < 0 || input[0] > 64) return -1;
    usz count = (usz)input[0];
    if (length != 1 + 4 * count) return -1;
    long[MAX_EVENTS] ys;
    Event[MAX_EVENTS] events;
    usz y_count = 0, event_count = 0;
    for (usz i = 0; i < count; i++) {
        long x1 = input[1 + 4 * i], y1 = input[2 + 4 * i];
        long x2 = input[3 + 4 * i], y2 = input[4 + 4 * i];
        if (x1 < -1000000000 || x1 > 1000000000 || x2 < -1000000000 || x2 > 1000000000
                || y1 < -1000000000 || y1 > 1000000000 || y2 < -1000000000 || y2 > 1000000000
                || x1 >= x2 || y1 >= y2) return -1;
        ys[y_count++] = y1; ys[y_count++] = y2;
        events[event_count++] = {x1, y1, y2, 1};
        events[event_count++] = {x2, y1, y2, -1};
    }
    if (count == 0) return 0;
    sort_values(&ys[0], y_count);
    usz unique_count = 1;
    for (usz i = 1; i < y_count; i++) {
        if (ys[i] != ys[unique_count - 1]) ys[unique_count++] = ys[i];
    }
    sort_events(&events[0], event_count);
    long[TREE_SIZE] cover = zeroed;
    long[TREE_SIZE] covered = zeroed;
    usz intervals = unique_count - 1;
    long area = 0, previous_x = events[0].x;
    usz event = 0;
    while (event < event_count) {
        long x = events[event].x;
        area += covered[1] * (x - previous_x);
        usz finish = event;
        while (finish < event_count && events[finish].x == x) finish++;
        for (long delta = 1; delta >= -1; delta -= 2) {
            for (usz i = event; i < finish; i++) {
                if (events[i].delta != delta) continue;
                usz low = lower_bound(&ys[0], unique_count, events[i].y1);
                usz high = lower_bound(&ys[0], unique_count, events[i].y2);
                update(1, 0, intervals, low, high, delta, &ys[0], &cover[0], &covered[0]);
            }
        }
        previous_x = x;
        event = finish;
    }
    return area;
}
