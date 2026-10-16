/// Return an integer Jarvis-scan hull in counter-clockwise order.
const MAX_POINTS: usize = 64;
const MIN_COORDINATE: i64 = -10_000;
const MAX_COORDINATE: i64 = 10_000;

fn orientation(a: (i64, i64), b: (i64, i64), c: (i64, i64)) -> i64 {
    (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0)
}

unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn jarvis_scan(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 {
        return -1;
    }
    let point_count = *input;
    if !(0..=MAX_POINTS as i64).contains(&point_count) {
        return -1;
    }
    let count = point_count as usize;
    if length != 1 + 2 * count {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let mut points = [(0_i64, 0_i64); MAX_POINTS];
    for index in 0..count {
        let x = input[1 + 2 * index];
        let y = input[2 + 2 * index];
        if !(MIN_COORDINATE..=MAX_COORDINATE).contains(&x)
            || !(MIN_COORDINATE..=MAX_COORDINATE).contains(&y)
        {
            return -1;
        }
        points[index] = (x, y);
    }
    if count <= 2 {
        return 0;
    }
    for first in 0..count {
        for second in first + 1..count {
            if points[first] == points[second] {
                return -1;
            }
        }
    }
    for first in 0..count - 2 {
        for second in first + 1..count - 1 {
            for third in second + 1..count {
                if orientation(points[first], points[second], points[third]) == 0 {
                    return -1;
                }
            }
        }
    }

    let mut start = 0;
    for index in 1..count {
        if points[index].0 < points[start].0
            || (points[index].0 == points[start].0 && points[index].1 < points[start].1)
        {
            start = index;
        }
    }
    let mut hull = [0_usize; MAX_POINTS];
    let mut hull_count = 0;
    let mut current = start;
    loop {
        if hull_count == count {
            return -1;
        }
        hull[hull_count] = current;
        hull_count += 1;
        let mut candidate = (current + 1) % count;
        for index in 0..count {
            if orientation(points[current], points[index], points[candidate]) > 0 {
                candidate = index;
            }
        }
        if candidate == start {
            break;
        }
        current = candidate;
    }
    let bytes = hull_count * 16;
    if output.is_null() || capacity < bytes {
        return -2;
    }
    for index in 0..hull_count {
        put_i64(output, index * 16, points[hull[index]].0);
        put_i64(output, index * 16 + 8, points[hull[index]].1);
    }
    bytes as i64
}
