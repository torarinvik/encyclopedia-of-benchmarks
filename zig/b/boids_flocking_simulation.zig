const max_boids: usize = 16;
const separation_scale: i64 = 256;

const Vec2 = struct { x: i64, y: i64 };

fn truncZero(numerator: i64, denominator: i64) i64 {
    return if (numerator < 0) -@divTrunc(-numerator, denominator) else @divTrunc(numerator, denominator);
}

fn ceilSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high: i64 = 4096;
    while (low < high) {
        const middle = @divTrunc(low + high, 2);
        if (middle * middle < value) low = middle + 1 else high = middle;
    }
    return low;
}

fn capVector(x: i64, y: i64, limit: i64) Vec2 {
    const squared = x * x + y * y;
    if (squared <= limit * limit) return .{ .x = x, .y = y };
    if (limit == 0) return .{ .x = 0, .y = 0 };
    const length = ceilSqrt(squared);
    return .{ .x = truncZero(x * limit, length), .y = truncZero(y * limit, length) };
}

fn requestAcceleration(index: usize, count: usize, x: *const [max_boids]i64,
    y: *const [max_boids]i64, vx: *const [max_boids]i64, vy: *const [max_boids]i64,
    radius_squared: i64, max_acceleration: i64) Vec2 {
    var sx: i64 = 0;
    var sy: i64 = 0;
    var velocity_x: i64 = 0;
    var velocity_y: i64 = 0;
    var offset_x: i64 = 0;
    var offset_y: i64 = 0;
    var neighbors: i64 = 0;
    for (0..count) |other| {
        if (other == index) continue;
        const dx = x[other] - x[index];
        const dy = y[other] - y[index];
        const distance_squared = dx * dx + dy * dy;
        if (distance_squared > radius_squared) continue;
        neighbors += 1;
        if (distance_squared == 0) {
            sx += if (index < other) -separation_scale else separation_scale;
        } else {
            const length = ceilSqrt(distance_squared);
            sx += truncZero(-dx * separation_scale, length);
            sy += truncZero(-dy * separation_scale, length);
        }
        velocity_x += vx[other];
        velocity_y += vy[other];
        offset_x += dx;
        offset_y += dy;
    }
    if (neighbors == 0) return .{ .x = 0, .y = 0 };
    const requests = [3]Vec2{
        capVector(truncZero(sx, neighbors), truncZero(sy, neighbors), max_acceleration),
        capVector(truncZero(velocity_x, neighbors) - vx[index],
                  truncZero(velocity_y, neighbors) - vy[index], max_acceleration),
        capVector(truncZero(offset_x, neighbors), truncZero(offset_y, neighbors), max_acceleration),
    };
    var ax: i64 = 0;
    var ay: i64 = 0;
    var used: i64 = 0;
    for (requests) |request| {
        const remaining = max_acceleration - used;
        if (remaining <= 0) break;
        const length = ceilSqrt(request.x * request.x + request.y * request.y);
        if (length == 0) continue;
        if (length <= remaining) {
            ax += request.x;
            ay += request.y;
            used += length;
        } else {
            const trimmed = capVector(request.x, request.y, remaining);
            ax += trimmed.x;
            ay += trimmed.y;
            break;
        }
    }
    return .{ .x = ax, .y = ay };
}

fn storeI32Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| {
        const shift: u5 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn boids_flocking_simulation(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 9 or length > 70) return -1;
    const values = input.?[0..length];
    const n_value = values[0];
    const steps = values[1];
    const radius = values[2];
    const max_speed = values[3];
    const max_acceleration = values[4];
    if (n_value < 1 or n_value > 16 or steps < 0 or steps > 16
        or radius < 0 or radius > 128 or max_speed < 1 or max_speed > 32
        or max_acceleration < 0 or max_acceleration > 8
        or length != 5 + 4 * @as(usize, @intCast(n_value))) return -1;
    const n: usize = @intCast(n_value);
    var x: [max_boids]i64 = @splat(0);
    var y: [max_boids]i64 = @splat(0);
    var vx: [max_boids]i64 = @splat(0);
    var vy: [max_boids]i64 = @splat(0);
    var next_x: [max_boids]i64 = @splat(0);
    var next_y: [max_boids]i64 = @splat(0);
    var next_vx: [max_boids]i64 = @splat(0);
    var next_vy: [max_boids]i64 = @splat(0);
    for (0..n) |i| {
        x[i] = values[5 + 4 * i];
        y[i] = values[6 + 4 * i];
        vx[i] = values[7 + 4 * i];
        vy[i] = values[8 + 4 * i];
        if (x[i] < -256 or x[i] > 256 or y[i] < -256 or y[i] > 256
            or vx[i] < -32 or vx[i] > 32 or vy[i] < -32 or vy[i] > 32
            or vx[i] * vx[i] + vy[i] * vy[i] > max_speed * max_speed) return -1;
    }
    const needed = 16 * n;
    if (output == null or output_capacity < needed) return -2;
    const radius_squared = radius * radius;
    for (0..@as(usize, @intCast(steps))) |_| {
        for (0..n) |i| {
            const acceleration = requestAcceleration(i, n, &x, &y, &vx, &vy, radius_squared, max_acceleration);
            const velocity = capVector(vx[i] + acceleration.x, vy[i] + acceleration.y, max_speed);
            next_vx[i] = velocity.x;
            next_vy[i] = velocity.y;
            next_x[i] = x[i] + velocity.x;
            next_y[i] = y[i] + velocity.y;
        }
        for (0..n) |i| {
            x[i] = next_x[i];
            y[i] = next_y[i];
            vx[i] = next_vx[i];
            vy[i] = next_vy[i];
        }
    }
    for (0..n) |i| {
        storeI32Le(output.?, 16 * i, x[i]);
        storeI32Le(output.?, 16 * i + 4, y[i]);
        storeI32Le(output.?, 16 * i + 8, vx[i]);
        storeI32Le(output.?, 16 * i + 12, vy[i]);
    }
    return @intCast(needed);
}
