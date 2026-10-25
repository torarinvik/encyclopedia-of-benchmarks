const max_leaves: i64 = 4;
const max_passes: i64 = 4;
const g_epsilon: f64 = 0.000001;
const h_epsilon: f64 = 0.000001;

fn findG(p: f64, q: f64) f64 { return p * p + q * q - 0.8; }
fn findH(p: f64, q: f64) f64 { return p - 5.0 * q; }

fn gradientF(p: f64, q: f64, pi_r: f64, pi_i: f64, gradient: *[2]f64) f64 {
    gradient[0] = 1.0 / (1.0 + p) - pi_r;
    gradient[1] = 1.0 / (1.0 + q) - pi_i;
    const magnitude = @sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1]);
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    return magnitude;
}

fn gradientG(p: f64, q: f64, gradient: *[2]f64) f64 {
    gradient[0] = 2.0 * p;
    gradient[1] = 2.0 * q;
    const magnitude = @sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1]);
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    return magnitude;
}

fn gradientH(gradient: *[2]f64) f64 {
    const magnitude = @sqrt(26.0);
    gradient[0] = 1.0 / magnitude;
    gradient[1] = -5.0 / magnitude;
    return magnitude;
}

fn secondGradientF(p: f64, q: f64, pi_r: f64, pi_i: f64, result: *[2]f64) void {
    const p_inv = 1.0 / (p + 1.0);
    const q_inv = 1.0 / (q + 1.0);
    const p_term = p_inv - pi_r;
    const q_term = q_inv - pi_i;
    const magnitude = @sqrt(p_term * p_term + q_term * q_term);
    result[0] = -p_inv * p_inv * p_term / magnitude;
    result[1] = -q_inv * q_inv * q_term / magnitude;
}

fn makeOrthogonal(modified: *[2]f64, fixed: *const [2]f64) f64 {
    const dot = modified[0] * fixed[0] + modified[1] * fixed[1];
    modified[0] -= dot * fixed[0];
    modified[1] -= dot * fixed[1];
    const length = @sqrt(modified[0] * modified[0] + modified[1] * modified[1]);
    modified[0] /= length;
    modified[1] /= length;
    if (1.0 - dot * dot < 0.0) return 0.0;
    return @sqrt(1.0 - dot * dot);
}

fn optimizeOne(p: *f64, q: *f64, pi_r: f64, pi_i: f64) void {
    var grad_f: [2]f64 = .{ 0.0, 0.0 };
    var grad_g: [2]f64 = .{ 0.0, 0.0 };
    var grad_h: [2]f64 = .{ 0.0, 0.0 };
    var dd_grad_f: [2]f64 = .{ 0.0, 0.0 };
    const h = findH(p.*, q.*);
    if (@abs(h) > h_epsilon) {
        const magnitude = gradientH(&grad_h);
        const total = h / magnitude;
        p.* -= total * grad_h[0];
        q.* -= total * grad_h[1];
    }
    const g = findG(p.*, q.*);
    if (g > g_epsilon) {
        var magnitude = gradientG(p.*, q.*, &grad_g);
        _ = gradientH(&grad_h);
        magnitude *= makeOrthogonal(&grad_g, &grad_h);
        const total = g / magnitude;
        p.* -= total * grad_g[0];
        q.* -= total * grad_g[1];
    }
    var magnitude = gradientF(p.*, q.*, pi_r, pi_i, &grad_f);
    secondGradientF(p.*, q.*, pi_r, pi_i, &dd_grad_f);
    var total = grad_f[0] * dd_grad_f[0] + grad_f[1] * dd_grad_f[1];
    magnitude /= @abs(total);
    _ = gradientH(&grad_h);
    magnitude *= makeOrthogonal(&grad_f, &grad_h);
    _ = gradientG(p.*, q.*, &grad_g);
    total = grad_f[0] * grad_g[0] + grad_f[1] * grad_g[1];
    if (total > 0.0) {
        const max_dist = -findG(p.*, q.*) / total;
        if (magnitude > max_dist) magnitude = max_dist;
    }
    p.* += magnitude * grad_f[0];
    q.* += magnitude * grad_f[1];
}

fn solveVoltage(p: *f64, q: *f64, resistance: f64, reactance: f64, alpha: *f64, beta: *f64) void {
    var a = resistance * resistance + reactance * reactance;
    var b = 2.0 * resistance * reactance * q.* - 2.0 * reactance * reactance * p.* - resistance;
    var c = resistance * q.* - reactance * p.*;
    c = c * c + resistance * p.*;
    const root = (-b - @sqrt(b * b - 4.0 * a * c)) / (2.0 * a);
    q.* += ((root - p.*) * reactance) / resistance;
    p.* = root;
    a = 2.0 * resistance * p.*;
    b = 2.0 * reactance * q.*;
    alpha.* = a / (1.0 - a - b);
    beta.* = b / (1.0 - a - b);
}

pub export fn olden_power(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const leaves_value = input[0];
    const passes_value = input[1];
    if (leaves_value < 1 or leaves_value > max_leaves or passes_value < 0 or passes_value > max_passes) return -1;
    const leaves: usize = @intCast(leaves_value);
    const passes: usize = @intCast(passes_value);
    var leaf_p: [4]f64 = .{ 1.0, 1.0, 1.0, 1.0 };
    var leaf_q: [4]f64 = .{ 1.0, 1.0, 1.0, 1.0 };
    var branch_alpha: f64 = 0.0;
    var branch_beta: f64 = 0.0;
    var lateral_alpha: f64 = 0.0;
    var lateral_beta: f64 = 0.0;
    const theta_r: f64 = 0.8;
    const theta_i: f64 = 0.16;
    var work_count: i64 = 0;
    var pass: usize = 0;
    while (pass < passes) : (pass += 1) {
        const lateral_pi_r = theta_r + lateral_alpha * (theta_r + (theta_i * 0.000001) / (1.0 / 300000.0));
        const lateral_pi_i = theta_i + lateral_beta * (theta_i + (theta_r * (1.0 / 300000.0)) / 0.000001);
        const branch_pi_r = lateral_pi_r + branch_alpha * (theta_r + (theta_i * 0.00002) / 0.0001);
        const branch_pi_i = lateral_pi_i + branch_beta * (theta_i + (theta_r * 0.0001) / 0.00002);
        var branch_p: f64 = 0.0;
        var branch_q: f64 = 0.0;
        var leaf: usize = 0;
        while (leaf < leaves) : (leaf += 1) {
            optimizeOne(&leaf_p[leaf], &leaf_q[leaf], branch_pi_r, branch_pi_i);
            if (leaf_p[leaf] < 0.0) {
                leaf_p[leaf] = 0.0;
                leaf_q[leaf] = 0.0;
            }
            branch_p += leaf_p[leaf];
            branch_q += leaf_q[leaf];
            work_count += 1;
        }
        solveVoltage(&branch_p, &branch_q, 0.0001, 0.00002, &branch_alpha, &branch_beta);
        var lateral_p = branch_p;
        var lateral_q = branch_q;
        solveVoltage(&lateral_p, &lateral_q, 1.0 / 300000.0, 0.000001, &lateral_alpha, &lateral_beta);
    }
    var state_projection: i64 = 0;
    var leaf: usize = 0;
    while (leaf < leaves) : (leaf += 1) {
        state_projection += @intFromFloat(@floor(leaf_p[leaf] * 1000.0 + 0.5));
        state_projection += 2 * @as(i64, @intFromFloat(@floor(leaf_q[leaf] * 1000.0 + 0.5)));
    }
    state_projection += @intFromFloat(@floor(branch_alpha * 1000.0 + 0.5));
    state_projection += 2 * @as(i64, @intFromFloat(@floor(branch_beta * 1000.0 + 0.5)));
    state_projection += @intFromFloat(@floor(lateral_alpha * 1000.0 + 0.5));
    state_projection += 2 * @as(i64, @intFromFloat(@floor(lateral_beta * 1000.0 + 0.5)));
    return state_projection + work_count;
}
