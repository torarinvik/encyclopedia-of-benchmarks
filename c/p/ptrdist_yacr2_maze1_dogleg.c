/* Clean-room bounded YACR2 Maze1 profile; rights status is documented with the package. */
#include <stddef.h>
#include <stdint.h>

#define YACR_MAX_COLUMNS 16
#define YACR_MAX_TRACKS 16

static int free_vertical(const int64_t *v, size_t plane, size_t columns,
                         size_t x, size_t y1, size_t y2) {
    const size_t lo = y1 < y2 ? y1 : y2;
    const size_t hi = y1 < y2 ? y2 : y1;
    for (size_t y = lo; y <= hi; ++y)
        if (v[plane + y * columns + (x - 1)] != 0) return 0;
    return 1;
}

static int free_horizontal(const int64_t *v, size_t plane, size_t columns,
                           size_t x1, size_t x2, size_t y) {
    const size_t lo = x1 < x2 ? x1 : x2;
    const size_t hi = x1 < x2 ? x2 : x1;
    for (size_t x = lo; x <= hi; ++x)
        if (v[plane + y * columns + (x - 1)] != 0) return 0;
    return 1;
}

static int try_dogleg(const int64_t *v, size_t plane, size_t vcv,
                      size_t columns, size_t tracks, size_t column,
                      size_t bottom, size_t top, int dx, int upper) {
    const size_t neighbor = (size_t)((int)column + dx);
    size_t straight_end, jog_y, other_start, other_end;
    if (upper) {
        straight_end = bottom;
        jog_y = bottom - 1;
        other_start = jog_y;
        other_end = top;
        return free_vertical(v, plane, columns, column, tracks + 1, straight_end) &&
               free_vertical(v, plane, columns, column, 0, jog_y) &&
               free_horizontal(v, plane, columns, column, neighbor, jog_y) &&
               free_vertical(v, plane, columns, neighbor, other_start, other_end) &&
               v[vcv + neighbor - 1] == 0;
    }
    straight_end = top;
    jog_y = top + 1;
    other_start = jog_y;
    other_end = bottom;
    return free_vertical(v, plane, columns, column, 0, straight_end) &&
           free_vertical(v, plane, columns, column, tracks + 1, jog_y) &&
           free_horizontal(v, plane, columns, column, neighbor, jog_y) &&
           free_vertical(v, plane, columns, neighbor, other_start, other_end) &&
           v[vcv + neighbor - 1] == 0;
}

int64_t ptrdist_yacr2_maze1_dogleg(const int64_t *input, size_t length) {
    if (input == NULL || length < 5) return -1;
    if (input[0] < 2 || input[0] > YACR_MAX_COLUMNS ||
        input[1] < 2 || input[1] > YACR_MAX_TRACKS) return -1;
    const size_t columns = (size_t)input[0], tracks = (size_t)input[1];
    if (input[2] < 1 || input[2] > (int64_t)columns) return -1;
    if (input[3] < 1 || input[3] >= input[4] || input[4] > (int64_t)tracks) return -1;
    const size_t column = (size_t)input[2], bottom = (size_t)input[3], top = (size_t)input[4];
    const size_t expected = 5 + columns + columns * (tracks + 2);
    if (length != expected) return -1;
    const size_t vcv = 5, plane = vcv + columns;
    for (size_t i = vcv; i < plane; ++i) if (input[i] != 0 && input[i] != 1) return -1;
    for (size_t i = plane; i < length; ++i) if (input[i] != 0 && input[i] != 1) return -1;

    /* The pinned launcher defines TODD: left upper, right upper, left lower, right lower. */
    if (bottom > 1 && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, 1)) return 1;
    if (bottom > 1 && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, 1)) return 2;
    if (top < tracks && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, 0)) return 3;
    if (top < tracks && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, 0)) return 4;
    return 0;
}
