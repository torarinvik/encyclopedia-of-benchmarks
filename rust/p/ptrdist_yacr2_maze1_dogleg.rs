/// Clean-room bounded YACR2 Maze1 profile; rights status is in the package README.
fn free_vertical(v: &[i64], plane: usize, columns: usize, x: usize, y1: usize, y2: usize) -> bool {
    let (lo, hi) = if y1 <= y2 { (y1, y2) } else { (y2, y1) };
    (lo..=hi).all(|y| v[plane + y * columns + (x - 1)] == 0)
}
fn free_horizontal(v: &[i64], plane: usize, columns: usize, x1: usize, x2: usize, y: usize) -> bool {
    let (lo, hi) = if x1 <= x2 { (x1, x2) } else { (x2, x1) };
    (lo..=hi).all(|x| v[plane + y * columns + (x - 1)] == 0)
}
fn try_dogleg(v: &[i64], plane: usize, vcv: usize, columns: usize, tracks: usize,
              column: usize, bottom: usize, top: usize, dx: isize, upper: bool) -> bool {
    let neighbor = (column as isize + dx) as usize;
    if upper {
        let jog = bottom - 1;
        free_vertical(v, plane, columns, column, tracks + 1, bottom)
            && free_vertical(v, plane, columns, column, 0, jog)
            && free_horizontal(v, plane, columns, column, neighbor, jog)
            && free_vertical(v, plane, columns, neighbor, jog, top)
            && v[vcv + neighbor - 1] == 0
    } else {
        let jog = top + 1;
        free_vertical(v, plane, columns, column, 0, top)
            && free_vertical(v, plane, columns, column, tracks + 1, jog)
            && free_horizontal(v, plane, columns, column, neighbor, jog)
            && free_vertical(v, plane, columns, neighbor, jog, bottom)
            && v[vcv + neighbor - 1] == 0
    }
}

#[no_mangle]
pub extern "C" fn ptrdist_yacr2_maze1_dogleg(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 { return -1; }
    let head = unsafe { std::slice::from_raw_parts(input, 5) };
    if !(2..=16).contains(&head[0]) || !(2..=16).contains(&head[1]) { return -1; }
    let (columns, tracks) = (head[0] as usize, head[1] as usize);
    if head[2] < 1 || head[2] > head[0] || head[3] < 1 || head[3] >= head[4] || head[4] > head[1] { return -1; }
    let (column, bottom, top) = (head[2] as usize, head[3] as usize, head[4] as usize);
    let expected = 5 + columns + columns * (tracks + 2);
    if length != expected { return -1; }
    let v = unsafe { std::slice::from_raw_parts(input, length) };
    let vcv = 5;
    let plane = vcv + columns;
    if v[vcv..plane].iter().chain(v[plane..].iter()).any(|&x| x != 0 && x != 1) { return -1; }

    if bottom > 1 && column > 1 && try_dogleg(v, plane, vcv, columns, tracks, column, bottom, top, -1, true) { return 1; }
    if bottom > 1 && column < columns && try_dogleg(v, plane, vcv, columns, tracks, column, bottom, top, 1, true) { return 2; }
    if top < tracks && column > 1 && try_dogleg(v, plane, vcv, columns, tracks, column, bottom, top, -1, false) { return 3; }
    if top < tracks && column < columns && try_dogleg(v, plane, vcv, columns, tracks, column, bottom, top, 1, false) { return 4; }
    0
}
