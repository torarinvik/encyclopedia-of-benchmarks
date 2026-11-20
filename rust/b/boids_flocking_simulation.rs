const MAX_BOIDS: usize = 16;
const SEPARATION_SCALE: i64 = 256;

fn trunc_zero(numerator: i64, denominator: i64) -> i64 {
    if numerator < 0 { -((-numerator) / denominator) } else { numerator / denominator }
}

fn ceil_sqrt(value: i64) -> i64 {
    let (mut low, mut high) = (0i64, 4096i64);
    while low < high {
        let middle = (low + high) / 2;
        if middle * middle < value { low = middle + 1; } else { high = middle; }
    }
    low
}

fn cap_vector(x: i64, y: i64, limit: i64) -> (i64, i64) {
    let squared = x * x + y * y;
    if squared <= limit * limit { return (x, y); }
    if limit == 0 { return (0, 0); }
    let length = ceil_sqrt(squared);
    (trunc_zero(x * limit, length), trunc_zero(y * limit, length))
}

fn request_acceleration(index: usize, count: usize, x: &[i64; MAX_BOIDS],
    y: &[i64; MAX_BOIDS], vx: &[i64; MAX_BOIDS], vy: &[i64; MAX_BOIDS],
    radius_squared: i64, max_acceleration: i64) -> (i64, i64) {
    let (mut sx, mut sy, mut velocity_x, mut velocity_y, mut offset_x, mut offset_y) = (0, 0, 0, 0, 0, 0);
    let mut neighbors = 0i64;
    for other in 0..count {
        if other == index { continue; }
        let dx = x[other] - x[index];
        let dy = y[other] - y[index];
        let distance_squared = dx * dx + dy * dy;
        if distance_squared > radius_squared { continue; }
        neighbors += 1;
        if distance_squared == 0 {
            sx += if index < other { -SEPARATION_SCALE } else { SEPARATION_SCALE };
        } else {
            let length = ceil_sqrt(distance_squared);
            sx += trunc_zero(-dx * SEPARATION_SCALE, length);
            sy += trunc_zero(-dy * SEPARATION_SCALE, length);
        }
        velocity_x += vx[other];
        velocity_y += vy[other];
        offset_x += dx;
        offset_y += dy;
    }
    if neighbors == 0 { return (0, 0); }
    let requests = [
        cap_vector(trunc_zero(sx, neighbors), trunc_zero(sy, neighbors), max_acceleration),
        cap_vector(trunc_zero(velocity_x, neighbors) - vx[index],
                   trunc_zero(velocity_y, neighbors) - vy[index], max_acceleration),
        cap_vector(trunc_zero(offset_x, neighbors), trunc_zero(offset_y, neighbors), max_acceleration),
    ];
    let (mut ax, mut ay, mut used) = (0i64, 0i64, 0i64);
    for (rx, ry) in requests {
        let remaining = max_acceleration - used;
        if remaining <= 0 { break; }
        let length = ceil_sqrt(rx * rx + ry * ry);
        if length == 0 { continue; }
        if length <= remaining {
            ax += rx; ay += ry; used += length;
        } else {
            let (tx, ty) = cap_vector(rx, ry, remaining);
            ax += tx; ay += ty;
            break;
        }
    }
    (ax, ay)
}

fn store_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as i32 as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn boids_flocking_simulation(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 9 || length > 70 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, steps, radius, max_speed, max_acceleration) =
        (values[0], values[1], values[2], values[3], values[4]);
    if n_value < 1 || n_value > MAX_BOIDS as i64 || steps < 0 || steps > 16
        || radius < 0 || radius > 128 || max_speed < 1 || max_speed > 32
        || max_acceleration < 0 || max_acceleration > 8
        || length != 5 + 4 * n_value as usize { return -1; }
    let n = n_value as usize;
    let mut x = [0i64; MAX_BOIDS]; let mut y = [0i64; MAX_BOIDS];
    let mut vx = [0i64; MAX_BOIDS]; let mut vy = [0i64; MAX_BOIDS];
    let mut next_x = [0i64; MAX_BOIDS]; let mut next_y = [0i64; MAX_BOIDS];
    let mut next_vx = [0i64; MAX_BOIDS]; let mut next_vy = [0i64; MAX_BOIDS];
    for i in 0..n {
        x[i] = values[5 + 4*i]; y[i] = values[6 + 4*i];
        vx[i] = values[7 + 4*i]; vy[i] = values[8 + 4*i];
        if x[i] < -256 || x[i] > 256 || y[i] < -256 || y[i] > 256
            || vx[i] < -32 || vx[i] > 32 || vy[i] < -32 || vy[i] > 32
            || vx[i] * vx[i] + vy[i] * vy[i] > max_speed * max_speed { return -1; }
    }
    let needed = 16 * n;
    if output.is_null() || output_capacity < needed { return -2; }
    let radius_squared = radius * radius;
    for _ in 0..steps {
        for i in 0..n {
            let (ax, ay) = request_acceleration(i, n, &x, &y, &vx, &vy, radius_squared, max_acceleration);
            let (new_vx, new_vy) = cap_vector(vx[i] + ax, vy[i] + ay, max_speed);
            next_vx[i] = new_vx; next_vy[i] = new_vy;
            next_x[i] = x[i] + new_vx; next_y[i] = y[i] + new_vy;
        }
        for i in 0..n {
            x[i] = next_x[i]; y[i] = next_y[i]; vx[i] = next_vx[i]; vy[i] = next_vy[i];
        }
    }
    for i in 0..n {
        store_i32_le(output, 16*i, x[i]); store_i32_le(output, 16*i + 4, y[i]);
        store_i32_le(output, 16*i + 8, vx[i]); store_i32_le(output, 16*i + 12, vy[i]);
    }
    needed as i64
}
