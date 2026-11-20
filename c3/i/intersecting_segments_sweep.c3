module intersecting_segments_sweep;

const usz MAX_SEGMENTS = 24, MAX_INPUT = 98;
const long COORD_MIN = -100, COORD_MAX = 100;

struct Segment { long x1; long y1; long x2; long y2; }
struct Event { long x; int id; bool start; }

fn long orient(long ax, long ay, long bx, long by, long cx, long cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

fn bool between(long a, long b, long point) {
    return a <= b ? a <= point && point <= b : b <= point && point <= a;
}

fn bool on_segment(long ax, long ay, long bx, long by, long px, long py) {
    return orient(ax, ay, bx, by, px, py) == 0 && between(ax, bx, px) && between(ay, by, py);
}

fn bool intersects(Segment a, Segment b) {
    long ab_c = orient(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1);
    long ab_d = orient(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2);
    long cd_a = orient(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1);
    long cd_b = orient(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2);
    if (ab_c == 0 && on_segment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1)) return true;
    if (ab_d == 0 && on_segment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2)) return true;
    if (cd_a == 0 && on_segment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1)) return true;
    if (cd_b == 0 && on_segment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2)) return true;
    return ((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) &&
           ((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0));
}

fn int compare_at_x(Segment a, int id_a, Segment b, int id_b, long x) {
    long adx = a.x2 - a.x1, bdx = b.x2 - b.x1;
    long a_num = a.y1 * adx + (a.y2 - a.y1) * (x - a.x1);
    long b_num = b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1);
    long left = a_num * bdx, right = b_num * adx;
    if (left != right) return left < right ? -1 : 1;
    long a_slope = (a.y2 - a.y1) * bdx;
    long b_slope = (b.y2 - b.y1) * adx;
    if (a_slope != b_slope) return a_slope < b_slope ? -1 : 1;
    return id_a < id_b ? -1 : id_a > id_b ? 1 : 0;
}

fn long intersecting_segments_sweep(long* input, usz length)
        @export("intersecting_segments_sweep") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)MAX_SEGMENTS || length != 1 + 4 * (usz)count_value) return -1;
    int count = (int)count_value;
    bool[201] used_x = {};
    Segment[MAX_SEGMENTS] segments = {};
    Event[2 * MAX_SEGMENTS] events = {};
    int event_count = 0;
    for (int id = 0; id < count; ++id) {
        usz offset = 1 + 4 * (usz)id;
        Segment segment = {input[offset], input[offset + 1], input[offset + 2], input[offset + 3]};
        if (segment.x1 < COORD_MIN || segment.x1 > COORD_MAX || segment.x2 < COORD_MIN || segment.x2 > COORD_MAX ||
            segment.y1 < COORD_MIN || segment.y1 > COORD_MAX || segment.y2 < COORD_MIN || segment.y2 > COORD_MAX ||
            segment.x1 >= segment.x2) return -1;
        usz first_x = (usz)(segment.x1 - COORD_MIN), second_x = (usz)(segment.x2 - COORD_MIN);
        if (used_x[first_x] || used_x[second_x]) return -1;
        used_x[first_x] = true; used_x[second_x] = true;
        segments[id] = segment;
        events[event_count++] = {segment.x1, id, true};
        events[event_count++] = {segment.x2, id, false};
    }
    for (int index = 1; index < event_count; ++index) {
        Event item = events[index];
        int position = index;
        while (position > 0 && events[position - 1].x > item.x) {
            events[position] = events[position - 1];
            --position;
        }
        events[position] = item;
    }
    int[MAX_SEGMENTS] active = {};
    int active_count = 0;
    for (int event_index = 0; event_index < event_count; ++event_index) {
        Event event = events[event_index];
        if (event.start) {
            int position = 0;
            while (position < active_count && compare_at_x(segments[active[position]], active[position],
                    segments[event.id], event.id, event.x) < 0) ++position;
            if (position > 0 && intersects(segments[active[position - 1]], segments[event.id])) return 1;
            if (position < active_count && intersects(segments[active[position]], segments[event.id])) return 1;
            for (int move = active_count; move > position; --move) active[move] = active[move - 1];
            active[position] = event.id;
            ++active_count;
        } else {
            int position = 0;
            while (position < active_count && active[position] != event.id) ++position;
            if (position == active_count) return -1;
            if (position > 0 && position + 1 < active_count &&
                intersects(segments[active[position - 1]], segments[active[position + 1]])) return 1;
            for (int move = position; move + 1 < active_count; ++move) active[move] = active[move + 1];
            --active_count;
        }
    }
    return 0;
}
