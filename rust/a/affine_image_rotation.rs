const MAX_DIMENSION: usize = 8;
const MAX_CELLS: usize = 64;
const MAX_INPUT_LENGTH: usize = 79;

#[derive(Clone, Copy)]
struct AxisSolution { first: i64, second: i64, translation: i64 }

fn solve_axis(x: &[i64; 3], y: &[i64; 3], target: &[i64; 3]) -> Option<AxisSolution> {
    let determinant = x[0] * (y[1] - y[2]) + x[1] * (y[2] - y[0]) + x[2] * (y[0] - y[1]);
    if determinant == 0 { return None; }
    let first = target[0] * (y[1] - y[2]) + target[1] * (y[2] - y[0]) + target[2] * (y[0] - y[1]);
    let second = x[0] * (target[1] - target[2]) + x[1] * (target[2] - target[0]) + x[2] * (target[0] - target[1]);
    let translation = x[0] * (y[1] * target[2] - y[2] * target[1])
        + x[1] * (y[2] * target[0] - y[0] * target[2])
        + x[2] * (y[0] * target[1] - y[1] * target[0]);
    if first % determinant != 0 || second % determinant != 0 || translation % determinant != 0 { return None; }
    Some(AxisSolution { first: first / determinant, second: second / determinant, translation: translation / determinant })
}

#[no_mangle]
pub unsafe extern "C" fn affine_image_rotation(input: *const i32, length: usize,
                                                output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let rows_value = values[0]; let cols_value = values[1];
    if !(1..=MAX_DIMENSION as i32).contains(&rows_value) || !(1..=MAX_DIMENSION as i32).contains(&cols_value) { return -1; }
    let rows = rows_value as usize; let cols = cols_value as usize; let cells = rows * cols;
    if length != 14 + cells { return -1; }
    let mut pixels = [0u8; MAX_CELLS];
    for i in 0..cells {
        if !(0..=255).contains(&values[2+i]) { return -1; }
        pixels[i] = values[2+i] as u8;
    }
    let point_offset = 2 + cells;
    let mut sx = [0i64;3]; let mut sy = [0i64;3]; let mut dx = [0i64;3]; let mut dy = [0i64;3];
    for i in 0..3 {
        sx[i] = i64::from(values[point_offset+2*i]); sy[i] = i64::from(values[point_offset+2*i+1]);
        dx[i] = i64::from(values[point_offset+6+2*i]); dy[i] = i64::from(values[point_offset+7+2*i]);
        if !(-16..=16).contains(&sx[i]) || !(-16..=16).contains(&sy[i]) || !(-16..=16).contains(&dx[i]) || !(-16..=16).contains(&dy[i]) { return -1; }
    }
    let Some(x_axis) = solve_axis(&sx, &sy, &dx) else { return -1; };
    let Some(y_axis) = solve_axis(&sx, &sy, &dy) else { return -1; };
    let (a,b,tx)=(x_axis.first,x_axis.second,x_axis.translation);
    let (c,d,ty)=(y_axis.first,y_axis.second,y_axis.translation);
    if !(-2..=2).contains(&a) || !(-2..=2).contains(&b) || !(-2..=2).contains(&c) || !(-2..=2).contains(&d) || !(-16..=16).contains(&tx) || !(-16..=16).contains(&ty) { return -1; }
    let determinant=a*d-b*c;
    if determinant != -1 && determinant != 1 { return -1; }
    for i in 0..3 { if dx[i] != a*sx[i]+b*sy[i]+tx || dy[i] != c*sx[i]+d*sy[i]+ty { return -1; } }
    if output.is_null() || capacity < cells { return -2; }
    let out = std::slice::from_raw_parts_mut(output, cells);
    let mut written=0;
    for y in 0..cols as i64 { for x in 0..rows as i64 {
        let px=x-tx; let py=y-ty;
        let source_x=(d*px-b*py)/determinant; let source_y=(-c*px+a*py)/determinant;
        out[written]=if source_x>=0&&source_x<cols as i64&&source_y>=0&&source_y<rows as i64 { pixels[source_y as usize*cols+source_x as usize] } else { 0 };
        written+=1;
    }}
    cells as i64
}
