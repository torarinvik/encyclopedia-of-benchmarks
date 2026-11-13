const MAX_LINES: usize = 32;
const MAX_QUERIES: usize = 32;
const MAX_LENGTH: usize = 99;
const INVALID: i64 = i64::MIN;

#[derive(Clone, Copy)]
struct Line { slope: i64, intercept: i64 }

fn value(line: Line, x: i64) -> i64 { line.slope * x + line.intercept }

fn redundant(a: Line, b: Line, c: Line) -> bool {
    (b.intercept - a.intercept) * (b.slope - c.slope)
        >= (c.intercept - b.intercept) * (a.slope - b.slope)
}

#[no_mangle]
pub extern "C" fn monotone_convex_hull_trick(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_LENGTH { return INVALID; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    if !(1..=MAX_LINES as i64).contains(&packed[0])
        || !(0..=MAX_QUERIES as i64).contains(&packed[1]) { return INVALID; }
    let line_count = packed[0] as usize;
    let query_count = packed[1] as usize;
    if length != 2 + 2 * line_count + query_count { return INVALID; }

    let mut hull = [Line { slope: 0, intercept: 0 }; MAX_LINES];
    let mut hull_count = 0usize;
    let mut previous_slope = i64::MAX;
    let mut cursor = 2usize;
    for _ in 0..line_count {
        let line = Line { slope: packed[cursor], intercept: packed[cursor + 1] };
        cursor += 2;
        if !(-1000..=1000).contains(&line.slope) || !(-10000..=10000).contains(&line.intercept)
            || line.slope >= previous_slope { return INVALID; }
        previous_slope = line.slope;
        while hull_count >= 2 && redundant(hull[hull_count - 2], hull[hull_count - 1], line) { hull_count -= 1; }
        hull[hull_count] = line;
        hull_count += 1;
    }

    let mut front = 0usize;
    let mut previous_x = i64::MIN;
    let mut checksum = 0i64;
    for i in 0..query_count {
        let x = packed[cursor + i];
        if !(-1000..=1000).contains(&x) || (i != 0 && x < previous_x) { return INVALID; }
        previous_x = x;
        while front + 1 < hull_count && value(hull[front + 1], x) <= value(hull[front], x) { front += 1; }
        checksum += (i as i64 + 1) * value(hull[front], x);
    }
    checksum
}
