#include <stddef.h>
#include <stdint.h>

#define RUAS_MAX_RECTANGLES 64
#define RUAS_MAX_EVENTS (2 * RUAS_MAX_RECTANGLES)
#define RUAS_TREE_SIZE 512
#define RUAS_MIN_COORD (-INT64_C(1000000000))
#define RUAS_MAX_COORD INT64_C(1000000000)

typedef struct {
    int64_t x;
    int64_t y1;
    int64_t y2;
    int64_t delta;
} ruas_event;

static void ruas_sift_i64(int64_t *items, size_t root, size_t end) {
    while (root * 2 + 1 < end) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && items[child] < items[child + 1]) ++child;
        if (items[root] >= items[child]) return;
        int64_t value = items[root]; items[root] = items[child]; items[child] = value;
        root = child;
    }
}

static void ruas_sort_i64(int64_t *items, size_t count) {
    for (size_t start = count / 2; start > 0; --start) ruas_sift_i64(items, start - 1, count);
    for (size_t end = count; end > 1; --end) {
        int64_t value = items[0]; items[0] = items[end - 1]; items[end - 1] = value;
        ruas_sift_i64(items, 0, end - 1);
    }
}

static void ruas_sift_events(ruas_event *events, size_t root, size_t end) {
    while (root * 2 + 1 < end) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && events[child].x < events[child + 1].x) ++child;
        if (events[root].x >= events[child].x) return;
        ruas_event value = events[root]; events[root] = events[child]; events[child] = value;
        root = child;
    }
}

static void ruas_sort_events(ruas_event *events, size_t count) {
    for (size_t start = count / 2; start > 0; --start) ruas_sift_events(events, start - 1, count);
    for (size_t end = count; end > 1; --end) {
        ruas_event value = events[0]; events[0] = events[end - 1]; events[end - 1] = value;
        ruas_sift_events(events, 0, end - 1);
    }
}

static size_t ruas_lower_bound(const int64_t *items, size_t count, int64_t value) {
    size_t low = 0, high = count;
    while (low < high) {
        size_t middle = low + (high - low) / 2;
        if (items[middle] < value) low = middle + 1;
        else high = middle;
    }
    return low;
}

static void ruas_update(size_t node, size_t left, size_t right,
                        size_t query_left, size_t query_right, int64_t delta,
                        const int64_t *ys, int64_t *cover, int64_t *length) {
    if (query_left <= left && right <= query_right) {
        cover[node] += delta;
    } else {
        size_t middle = left + (right - left) / 2;
        if (query_left < middle) ruas_update(node * 2, left, middle, query_left, query_right,
                                              delta, ys, cover, length);
        if (query_right > middle) ruas_update(node * 2 + 1, middle, right, query_left, query_right,
                                               delta, ys, cover, length);
    }
    if (cover[node] > 0) length[node] = ys[right] - ys[left];
    else if (right - left == 1) length[node] = 0;
    else length[node] = length[node * 2] + length[node * 2 + 1];
}

int64_t rectangle_union_area_sweep(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 258) return -1;
    int64_t count_value = input[0];
    if (count_value < 0 || count_value > RUAS_MAX_RECTANGLES) return -1;
    size_t count = (size_t)count_value;
    if (length != 1 + 4 * count) return -1;

    int64_t ys[RUAS_MAX_EVENTS];
    ruas_event events[RUAS_MAX_EVENTS];
    size_t y_count = 0, event_count = 0;
    for (size_t i = 0; i < count; ++i) {
        int64_t x1 = input[1 + 4 * i], y1 = input[2 + 4 * i];
        int64_t x2 = input[3 + 4 * i], y2 = input[4 + 4 * i];
        if (x1 < RUAS_MIN_COORD || x1 > RUAS_MAX_COORD || x2 < RUAS_MIN_COORD || x2 > RUAS_MAX_COORD
                || y1 < RUAS_MIN_COORD || y1 > RUAS_MAX_COORD || y2 < RUAS_MIN_COORD || y2 > RUAS_MAX_COORD
                || x1 >= x2 || y1 >= y2) return -1;
        ys[y_count++] = y1; ys[y_count++] = y2;
        events[event_count++] = (ruas_event){x1, y1, y2, 1};
        events[event_count++] = (ruas_event){x2, y1, y2, -1};
    }
    if (count == 0) return 0;

    ruas_sort_i64(ys, y_count);
    size_t unique_count = 1;
    for (size_t i = 1; i < y_count; ++i)
        if (ys[i] != ys[unique_count - 1]) ys[unique_count++] = ys[i];
    ruas_sort_events(events, event_count);
    int64_t cover[RUAS_TREE_SIZE] = {0};
    int64_t covered[RUAS_TREE_SIZE] = {0};
    int64_t area = 0, previous_x = events[0].x;
    size_t event = 0, intervals = unique_count - 1;
    while (event < event_count) {
        int64_t x = events[event].x;
        area += covered[1] * (x - previous_x);
        size_t group_end = event;
        while (group_end < event_count && events[group_end].x == x) ++group_end;
        for (int pass = 1; pass >= -1; pass -= 2) {
            for (size_t i = event; i < group_end; ++i) {
                if (events[i].delta != pass) continue;
                size_t low = ruas_lower_bound(ys, unique_count, events[i].y1);
                size_t high = ruas_lower_bound(ys, unique_count, events[i].y2);
                ruas_update(1, 0, intervals, low, high, events[i].delta, ys, cover, covered);
            }
        }
        previous_x = x;
        event = group_end;
    }
    return area;
}
