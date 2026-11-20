//! Independently authored draft; not compiled or run.
#[derive(Clone, Copy, Default)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy)]
struct Circle { x: i64, y: i64, den: i64, radius2: i64 }
fn distance(c: Circle, p: Point) -> i64 {
    let dx = p.x*c.den-c.x; let dy = p.y*c.den-c.y;
    dx*dx + dy*dy
}
fn point_circle(p: Point) -> Circle { Circle { x:p.x, y:p.y, den:1, radius2:0 } }
fn pair_circle(a: Point, b: Point) -> Circle {
    let mut c = Circle { x:a.x+b.x, y:a.y+b.y, den:2, radius2:0 };
    c.radius2 = distance(c, a); c
}
fn triple_circle(a: Point, b: Point, c: Point) -> Circle {
    let mut den = 2*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y));
    if den == 0 {
        let ab = pair_circle(a,b); let ac = pair_circle(a,c); let bc = pair_circle(b,c);
        if ab.radius2 >= ac.radius2 && ab.radius2 >= bc.radius2 { return ab; }
        return if ac.radius2 >= bc.radius2 { ac } else { bc };
    }
    let aa = a.x*a.x+a.y*a.y; let bb = b.x*b.x+b.y*b.y; let cc = c.x*c.x+c.y*c.y;
    let mut x = aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y);
    let mut y = aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x);
    if den < 0 { den = -den; x = -x; y = -y; }
    let mut result = Circle { x, y, den, radius2:0 };
    result.radius2 = distance(result, a); result
}

#[no_mangle]
pub unsafe extern "C" fn minimum_enclosing_circle_incremental_boundary(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(4..=194).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1+3*n { return -1; }
    let mut points = [Point::default(); 64];
    let mut order = [0usize; 64];
    let mut seen = [false; 64];
    for i in 0..n {
        let (x,y) = (values[1+2*i], values[2+2*i]);
        if !(-100..=100).contains(&x) || !(-100..=100).contains(&y) { return -1; }
        points[i] = Point{x,y};
    }
    for i in 0..n {
        let v = values[1+2*n+i];
        if v < 0 || v >= n as i64 || seen[v as usize] { return -1; }
        seen[v as usize] = true; order[i] = v as usize;
    }
    if output.is_null() || capacity < n { return -2; }
    let mut circle = point_circle(points[order[0]]);
    for i in 1..n {
        let a = points[order[i]];
        if distance(circle, a) <= circle.radius2 { continue; }
        circle = point_circle(a);
        for j in 0..i {
            let b = points[order[j]];
            if distance(circle, b) <= circle.radius2 { continue; }
            circle = pair_circle(a,b);
            for k in 0..j {
                let c = points[order[k]];
                if distance(circle,c) > circle.radius2 { circle = triple_circle(a,b,c); }
            }
        }
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, n) };
    for i in 0..n { out[i] = u8::from(distance(circle, points[i]) == circle.radius2); }
    n as i64
}
