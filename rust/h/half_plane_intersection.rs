const MAX_LINES: usize = 16;
const MAX_INPUT: usize = 37;
const BOX: i64 = 256;

#[derive(Clone, Copy, Default)]
struct Halfplane { a: i64, b: i64, c: i64 }
#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64, den: i64 }

fn abs64(x: i64) -> i64 { if x < 0 { -x } else { x } }
fn gcd64(mut a: i64, mut b: i64) -> i64 {
    a = abs64(a); b = abs64(b);
    while b != 0 { let r = a % b; a = b; b = r; }
    a
}
fn half(h: Halfplane) -> i32 { if h.b > 0 || (h.b == 0 && h.a >= 0) { 0 } else { 1 } }
fn line_less(x: Halfplane, y: Halfplane) -> bool {
    let (hx, hy) = (half(x), half(y));
    if hx != hy { return hx < hy; }
    let turn = x.a * y.b - x.b * y.a;
    if turn != 0 { return turn > 0; }
    x.c < y.c
}
fn intersection(x: Halfplane, y: Halfplane) -> Option<Point> {
    let mut det = x.a * y.b - y.a * x.b;
    if det == 0 { return None; }
    let (mut xn, mut yn) = (x.c * y.b - x.b * y.c, x.a * y.c - x.c * y.a);
    if det < 0 { det = -det; xn = -xn; yn = -yn; }
    let g = gcd64(gcd64(xn, yn), det);
    Some(Point { x: xn / g, y: yn / g, den: det / g })
}
fn outside(h: Halfplane, p: Point) -> bool { h.a * p.x + h.b * p.y > h.c * p.den }
fn same(x: Point, y: Point) -> bool { x.x * y.den == y.x * x.den && x.y * y.den == y.y * x.den }
fn orient(a: Point, b: Point, c: Point) -> i64 {
    let dx1 = b.x * a.den - a.x * b.den; let dy1 = b.y * a.den - a.y * b.den;
    let dx2 = c.x * b.den - b.x * c.den; let dy2 = c.y * b.den - b.y * c.den;
    dx1 * dy2 - dy1 * dx2
}
fn less_yx(a: Point, b: Point) -> bool {
    let y1 = a.y * b.den; let y2 = b.y * a.den;
    if y1 != y2 { y1 < y2 } else { a.x * b.den < b.x * a.den }
}
unsafe fn put_i64(out: *mut u8, offset: &mut usize, value: i64) {
    for (b, byte) in value.to_le_bytes().iter().enumerate() { *out.add(*offset + b) = *byte; }
    *offset += 8;
}

#[no_mangle]
pub unsafe extern "C" fn half_plane_intersection(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
    if v.is_null() || n < 1 || n > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(v, n);
    if input[0] < 0 || input[0] > 12 { return -1; }
    let count = input[0] as usize;
    if n != 1 + 3 * count { return -1; }
    let mut lines = [Halfplane::default(); MAX_LINES];
    let mut queue = [Halfplane::default(); MAX_LINES];
    let mut points = [Point::default(); MAX_LINES];
    let mut clean = [Point::default(); MAX_LINES];
    let mut line_count = 0;
    for i in 0..count {
        let (a, b, c) = (input[1 + 3 * i], input[2 + 3 * i], input[3 + 3 * i]);
        if !(-16..=16).contains(&a) || !(-16..=16).contains(&b) || !(-128..=128).contains(&c)
                || (a == 0 && b == 0) || gcd64(a, b) != 1 { return -1; }
        lines[line_count] = Halfplane { a, b, c }; line_count += 1;
    }
    for h in [Halfplane { a: 1, b: 0, c: BOX }, Halfplane { a: 0, b: 1, c: BOX },
              Halfplane { a: -1, b: 0, c: BOX }, Halfplane { a: 0, b: -1, c: BOX }] {
        lines[line_count] = h; line_count += 1;
    }
    for i in 1..line_count {
        let key = lines[i]; let mut j = i;
        while j > 0 && line_less(key, lines[j - 1]) { lines[j] = lines[j - 1]; j -= 1; }
        lines[j] = key;
    }
    let mut reduced = 0;
    for i in 0..line_count {
        if reduced > 0 && lines[i].a == lines[reduced - 1].a && lines[i].b == lines[reduced - 1].b { continue; }
        lines[reduced] = lines[i]; reduced += 1;
    }
    let (mut head, mut tail) = (0usize, 0usize);
    let mut empty = false;
    for i in 0..reduced {
        let h = lines[i];
        while tail - head > 1 {
            let Some(p) = intersection(queue[tail - 2], queue[tail - 1]) else { break; };
            if !outside(h, p) { break; } tail -= 1;
        }
        while tail - head > 1 {
            let Some(p) = intersection(queue[head], queue[head + 1]) else { break; };
            if !outside(h, p) { break; } head += 1;
        }
        if tail > head {
            let last = queue[tail - 1];
            if last.a * h.b - last.b * h.a == 0 {
                if last.a * h.a + last.b * h.b < 0 { empty = true; break; }
                if h.c < last.c { queue[tail - 1] = h; }
                continue;
            }
        }
        queue[tail] = h; tail += 1;
    }
    if empty { head = 0; tail = 0; }
    if tail - head >= 3 {
        while tail - head > 2 {
            let Some(p) = intersection(queue[tail - 2], queue[tail - 1]) else { break; };
            if !outside(queue[head], p) { break; } tail -= 1;
        }
        while tail - head > 2 {
            let Some(p) = intersection(queue[head], queue[head + 1]) else { break; };
            if !outside(queue[tail - 1], p) { break; } head += 1;
        }
    }
    let mut point_count = 0;
    if tail - head >= 3 {
        for i in head..tail {
            let next = if i + 1 == tail { head } else { i + 1 };
            let Some(p) = intersection(queue[i], queue[next]) else { point_count = 0; break; };
            points[point_count] = p; point_count += 1;
        }
    }
    let mut clean_count = 0;
    for p in points.iter().take(point_count) {
        if clean_count == 0 || !same(clean[clean_count - 1], *p) { clean[clean_count] = *p; clean_count += 1; }
    }
    if clean_count > 1 && same(clean[0], clean[clean_count - 1]) { clean_count -= 1; }
    let mut changed = true;
    while changed && clean_count >= 3 {
        changed = false;
        for i in 0..clean_count {
            let prev = (i + clean_count - 1) % clean_count; let next = (i + 1) % clean_count;
            if orient(clean[prev], clean[i], clean[next]) == 0 {
                for j in i..clean_count - 1 { clean[j] = clean[j + 1]; }
                clean_count -= 1; changed = true; break;
            }
        }
    }
    if clean_count < 3 { clean_count = 0; }
    if clean_count > 0 {
        let mut first = 0;
        for i in 1..clean_count { if less_yx(clean[i], clean[first]) { first = i; } }
        let old = clean;
        for i in 0..clean_count { clean[i] = old[(first + i) % clean_count]; }
    }
    let needed = (1 + 4 * clean_count) * 8;
    if needed > cap || out.is_null() { return -2; }
    let mut offset = 0; put_i64(out, &mut offset, clean_count as i64);
    for p in clean.iter().take(clean_count) {
        let gx = gcd64(p.x, p.den); let gy = gcd64(p.y, p.den);
        put_i64(out, &mut offset, p.x / gx); put_i64(out, &mut offset, p.den / gx);
        put_i64(out, &mut offset, p.y / gy); put_i64(out, &mut offset, p.den / gy);
    }
    needed as i64
}
