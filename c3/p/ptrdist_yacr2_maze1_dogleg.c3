// Clean-room bounded YACR2 Maze1 profile; rights status is documented in package README.
module ptrdist_yacr2_maze1_dogleg;

const usz MAX_COLUMNS = 16;
const usz MAX_TRACKS = 16;

fn bool free_vertical(long* v, usz plane, usz columns, usz x, usz y1, usz y2) {
    usz low = y1 < y2 ? y1 : y2;
    usz high = y1 < y2 ? y2 : y1;
    for (usz y = low; y <= high; y++) if (v[plane + y * columns + x - 1] != 0) return false;
    return true;
}
fn bool free_horizontal(long* v, usz plane, usz columns, usz x1, usz x2, usz y) {
    usz low = x1 < x2 ? x1 : x2;
    usz high = x1 < x2 ? x2 : x1;
    for (usz x = low; x <= high; x++) if (v[plane + y * columns + x - 1] != 0) return false;
    return true;
}
fn bool try_dogleg(long* v, usz plane, usz vcv, usz columns, usz tracks,
                   usz column, usz bottom, usz top, int dx, bool upper) {
    usz neighbor = (usz)((int)column + dx);
    if (upper) {
        usz jog = bottom - 1;
        return free_vertical(v, plane, columns, column, tracks + 1, bottom) &&
            free_vertical(v, plane, columns, column, 0, jog) &&
            free_horizontal(v, plane, columns, column, neighbor, jog) &&
            free_vertical(v, plane, columns, neighbor, jog, top) && v[vcv + neighbor - 1] == 0;
    }
    usz jog = top + 1;
    return free_vertical(v, plane, columns, column, 0, top) &&
        free_vertical(v, plane, columns, column, tracks + 1, jog) &&
        free_horizontal(v, plane, columns, column, neighbor, jog) &&
        free_vertical(v, plane, columns, neighbor, jog, bottom) && v[vcv + neighbor - 1] == 0;
}

long ptrdist_yacr2_maze1_dogleg(long* input, usz length) @export("ptrdist_yacr2_maze1_dogleg") {
    if (input == null || length < 5) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_COLUMNS || input[1] < 2 || input[1] > (long)MAX_TRACKS) return -1;
    usz columns = (usz)input[0], tracks = (usz)input[1];
    if (input[2] < 1 || input[2] > (long)columns || input[3] < 1 || input[3] >= input[4] || input[4] > (long)tracks) return -1;
    usz column = (usz)input[2], bottom = (usz)input[3], top = (usz)input[4];
    if (length != 5 + columns + columns * (tracks + 2)) return -1;
    usz vcv = 5, plane = vcv + columns;
    for (usz i = vcv; i < plane; i++) if (input[i] != 0 && input[i] != 1) return -1;
    for (usz i = plane; i < length; i++) if (input[i] != 0 && input[i] != 1) return -1;

    if (bottom > 1 && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, true)) return 1;
    if (bottom > 1 && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, true)) return 2;
    if (top < tracks && column > 1 && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, -1, false)) return 3;
    if (top < tracks && column < columns && try_dogleg(input, plane, vcv, columns, tracks, column, bottom, top, 1, false)) return 4;
    return 0;
}
