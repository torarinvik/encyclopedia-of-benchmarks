#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SWEEP_MAX_SEGMENTS 24
#define SWEEP_MAX_INPUT 98
#define SWEEP_COORD_MIN (-100)
#define SWEEP_COORD_MAX 100

typedef struct {
    int64_t x1, y1, x2, y2;
} Segment;

typedef struct {
    int64_t x;
    int id;
    bool start;
} Event;

static int64_t sweep_orientation(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                                 int64_t cx, int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static bool sweep_between(int64_t a, int64_t b, int64_t point) {
    return (a <= b && a <= point && point <= b) || (b < a && b <= point && point <= a);
}

static bool sweep_on_segment(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                             int64_t px, int64_t py) {
    return sweep_orientation(ax, ay, bx, by, px, py) == 0 &&
           sweep_between(ax, bx, px) && sweep_between(ay, by, py);
}

static bool sweep_intersects(Segment a, Segment b) {
    int64_t ab_c = sweep_orientation(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1);
    int64_t ab_d = sweep_orientation(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2);
    int64_t cd_a = sweep_orientation(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1);
    int64_t cd_b = sweep_orientation(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2);
    if (ab_c == 0 && sweep_on_segment(a.x1, a.y1, a.x2, a.y2, b.x1, b.y1)) return true;
    if (ab_d == 0 && sweep_on_segment(a.x1, a.y1, a.x2, a.y2, b.x2, b.y2)) return true;
    if (cd_a == 0 && sweep_on_segment(b.x1, b.y1, b.x2, b.y2, a.x1, a.y1)) return true;
    if (cd_b == 0 && sweep_on_segment(b.x1, b.y1, b.x2, b.y2, a.x2, a.y2)) return true;
    return ((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) &&
           ((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0));
}

static int sweep_compare_at_x(Segment a, int id_a, Segment b, int id_b, int64_t x) {
    int64_t adx = a.x2 - a.x1, bdx = b.x2 - b.x1;
    int64_t anum = a.y1 * adx + (a.y2 - a.y1) * (x - a.x1);
    int64_t bnum = b.y1 * bdx + (b.y2 - b.y1) * (x - b.x1);
    int64_t left = anum * bdx, right = bnum * adx;
    if (left != right) return left < right ? -1 : 1;
    int64_t aslope = (a.y2 - a.y1) * bdx;
    int64_t bslope = (b.y2 - b.y1) * adx;
    if (aslope != bslope) return aslope < bslope ? -1 : 1;
    return (id_a > id_b) - (id_a < id_b);
}

int64_t intersecting_segments_sweep(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > SWEEP_MAX_INPUT) return -1;
    int64_t count_raw = input[0];
    if (count_raw < 0 || count_raw > SWEEP_MAX_SEGMENTS ||
        length != (size_t)(1 + 4 * count_raw)) return -1;
    int count = (int)count_raw;
    bool used_x[201] = {false};
    Segment segments[SWEEP_MAX_SEGMENTS];
    Event events[2 * SWEEP_MAX_SEGMENTS];
    int event_count = 0;
    for (int id = 0; id < count; ++id) {
        size_t offset = 1 + (size_t)4 * (size_t)id;
        Segment segment = {input[offset], input[offset + 1], input[offset + 2], input[offset + 3]};
        if (segment.x1 < SWEEP_COORD_MIN || segment.x1 > SWEEP_COORD_MAX ||
            segment.x2 < SWEEP_COORD_MIN || segment.x2 > SWEEP_COORD_MAX ||
            segment.y1 < SWEEP_COORD_MIN || segment.y1 > SWEEP_COORD_MAX ||
            segment.y2 < SWEEP_COORD_MIN || segment.y2 > SWEEP_COORD_MAX ||
            segment.x1 >= segment.x2) return -1;
        int first_x = (int)(segment.x1 - SWEEP_COORD_MIN);
        int second_x = (int)(segment.x2 - SWEEP_COORD_MIN);
        if (used_x[first_x] || used_x[second_x]) return -1;
        used_x[first_x] = used_x[second_x] = true;
        segments[id] = segment;
        events[event_count++] = (Event){segment.x1, id, true};
        events[event_count++] = (Event){segment.x2, id, false};
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

    int active[SWEEP_MAX_SEGMENTS];
    int active_count = 0;
    for (int event_index = 0; event_index < event_count; ++event_index) {
        Event event = events[event_index];
        if (event.start) {
            int position = 0;
            while (position < active_count &&
                   sweep_compare_at_x(segments[active[position]], active[position],
                                      segments[event.id], event.id, event.x) < 0) ++position;
            if (position > 0 && sweep_intersects(segments[active[position - 1]], segments[event.id])) return 1;
            if (position < active_count && sweep_intersects(segments[active[position]], segments[event.id])) return 1;
            for (int move = active_count; move > position; --move) active[move] = active[move - 1];
            active[position] = event.id;
            ++active_count;
        } else {
            int position = 0;
            while (position < active_count && active[position] != event.id) ++position;
            if (position == active_count) return -1;
            if (position > 0 && position + 1 < active_count &&
                sweep_intersects(segments[active[position - 1]], segments[active[position + 1]])) return 1;
            for (int move = position; move + 1 < active_count; ++move) active[move] = active[move + 1];
            --active_count;
        }
    }
    return 0;
}
