// Clean-room bounded YACR2 Maze1 profile; rights status is documented in package README.
const MAX_COLUMNS: i64 = 16;
const MAX_TRACKS: i64 = 16;

fn freeVertical(v: []const i64, plane: usize, columns: usize, x: usize, y1: usize, y2: usize) bool {
    const low = @min(y1, y2);
    const high = @max(y1, y2);
    for (low..high + 1) |y| if (v[plane + y * columns + x - 1] != 0) return false;
    return true;
}
fn freeHorizontal(v: []const i64, plane: usize, columns: usize, x1: usize, x2: usize, y: usize) bool {
    const low = @min(x1, x2);
    const high = @max(x1, x2);
    for (low..high + 1) |x| if (v[plane + y * columns + x - 1] != 0) return false;
    return true;
}
fn tryDogleg(v: []const i64, plane: usize, vcv: usize, columns: usize, tracks: usize,
             column: usize, bottom: usize, top: usize, dx: isize, upper: bool) bool {
    const neighbor: usize = @intCast(@as(isize, @intCast(column)) + dx);
    if (upper) {
        const jog = bottom - 1;
        return freeVertical(v, plane, columns, column, tracks + 1, bottom) and
            freeVertical(v, plane, columns, column, 0, jog) and
            freeHorizontal(v, plane, columns, column, neighbor, jog) and
            freeVertical(v, plane, columns, neighbor, jog, top) and v[vcv + neighbor - 1] == 0;
    }
    const jog = top + 1;
    return freeVertical(v, plane, columns, column, 0, top) and
        freeVertical(v, plane, columns, column, tracks + 1, jog) and
        freeHorizontal(v, plane, columns, column, neighbor, jog) and
        freeVertical(v, plane, columns, neighbor, jog, bottom) and v[vcv + neighbor - 1] == 0;
}

pub export fn ptrdist_yacr2_maze1_dogleg(values: ?[*]const i64, length: usize) i64 {
    const input = values orelse return -1;
    if (length < 5) return -1;
    if (input[0] < 2 or input[0] > MAX_COLUMNS or input[1] < 2 or input[1] > MAX_TRACKS) return -1;
    const columns: usize = @intCast(input[0]);
    const tracks: usize = @intCast(input[1]);
    if (input[2] < 1 or input[2] > input[0] or input[3] < 1 or input[3] >= input[4] or input[4] > input[1]) return -1;
    const column: usize = @intCast(input[2]);
    const bottom: usize = @intCast(input[3]);
    const top: usize = @intCast(input[4]);
    const expected = 5 + columns + columns * (tracks + 2);
    if (length != expected) return -1;
    const slice = input[0..length];
    const vcv: usize = 5;
    const plane = vcv + columns;
    for (slice[vcv..plane]) |flag| if (flag != 0 and flag != 1) return -1;
    for (slice[plane..]) |cell| if (cell != 0 and cell != 1) return -1;

    if (bottom > 1 and column > 1 and tryDogleg(slice, plane, vcv, columns, tracks, column, bottom, top, -1, true)) return 1;
    if (bottom > 1 and column < columns and tryDogleg(slice, plane, vcv, columns, tracks, column, bottom, top, 1, true)) return 2;
    if (top < tracks and column > 1 and tryDogleg(slice, plane, vcv, columns, tracks, column, bottom, top, -1, false)) return 3;
    if (top < tracks and column < columns and tryDogleg(slice, plane, vcv, columns, tracks, column, bottom, top, 1, false)) return 4;
    return 0;
}
