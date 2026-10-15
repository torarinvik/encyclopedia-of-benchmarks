use std::slice;

#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }

fn contains(points: &[Point], center_x: f64, center_y: f64, radius: f64) -> bool {
    let radius_squared = radius * radius;
    points.iter().all(|point| {
        let dx = point.x as f64 - center_x;
        let dy = point.y as f64 - center_y;
        dx * dx + dy * dy <= radius_squared + 1.0e-12
    })
}

fn consider(points: &[Point], center_x: f64, center_y: f64, radius: f64,
            best: &mut Option<(f64, f64, f64)>) {
    if contains(points, center_x, center_y, radius) &&
       best.map_or(true, |(_, _, best_radius)| radius <= best_radius) {
        *best = Some((center_x, center_y, radius));
    }
}

unsafe fn write_circle(output: *mut u8, capacity: usize, center_x: f64,
                       center_y: f64, radius: f64) -> i64 {
    if output.is_null() || capacity < 24 { return -2; }
    for (value_index, value) in [center_x, center_y, radius].iter().enumerate() {
        let bytes = value.to_le_bytes();
        for byte_index in 0..8 { *output.add(value_index * 8 + byte_index) = bytes[byte_index]; }
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn smallest_circle(input: *const i64, length: usize,
                                           output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 24 || length % 2 != 0 { return -1; }
    let values = slice::from_raw_parts(input, length);
    let count = length / 2;
    if !(1..=12).contains(&count) { return -1; }
    let mut points = [Point::default(); 12];
    for index in 0..count {
        let x = values[2 * index];
        let y = values[2 * index + 1];
        if !(-100..=100).contains(&x) || !(-100..=100).contains(&y) { return -1; }
        points[index] = Point { x, y };
    }
    let points = &points[..count];
    if count == 1 {
        return write_circle(output, output_capacity, points[0].x as f64,
                            points[0].y as f64, 0.0);
    }
    let mut best = None;
    for i in 0..points.len() {
        for j in i + 1..points.len() {
            for k in j + 1..points.len() {
                let a = points[i]; let b = points[j]; let c = points[k];
                let (ax, ay, bx, by, cx, cy) = (a.x as f64, a.y as f64,
                    b.x as f64, b.y as f64, c.x as f64, c.y as f64);
                let denominator = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
                if denominator == 0.0 { continue; }
                let (a2, b2, c2) = (ax * ax + ay * ay, bx * bx + by * by, cx * cx + cy * cy);
                let center_x = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / denominator;
                let center_y = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / denominator;
                let dx = ax - center_x; let dy = ay - center_y;
                consider(points, center_x, center_y, (dx * dx + dy * dy).sqrt(), &mut best);
            }
        }
    }
    for i in 0..points.len() {
        for j in i + 1..points.len() {
            let center_x = (points[i].x as f64 + points[j].x as f64) / 2.0;
            let center_y = (points[i].y as f64 + points[j].y as f64) / 2.0;
            let dx = points[i].x as f64 - center_x;
            let dy = points[i].y as f64 - center_y;
            consider(points, center_x, center_y, (dx * dx + dy * dy).sqrt(), &mut best);
        }
    }
    match best {
        Some((center_x, center_y, radius)) => write_circle(output, output_capacity, center_x, center_y, radius),
        None => -1,
    }
}
