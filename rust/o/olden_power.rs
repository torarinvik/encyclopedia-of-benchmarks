const MAX_LEAVES: i64 = 4;
const MAX_PASSES: i64 = 4;
const G_EPSILON: f64 = 0.000001;
const H_EPSILON: f64 = 0.000001;

fn find_g(p: f64, q: f64) -> f64 { p * p + q * q - 0.8 }
fn find_h(p: f64, q: f64) -> f64 { p - 5.0 * q }

fn gradient_f(p: f64, q: f64, pi_r: f64, pi_i: f64, gradient: &mut [f64; 2]) -> f64 {
    gradient[0] = 1.0 / (1.0 + p) - pi_r;
    gradient[1] = 1.0 / (1.0 + q) - pi_i;
    let magnitude = (gradient[0] * gradient[0] + gradient[1] * gradient[1]).sqrt();
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    magnitude
}

fn gradient_g(p: f64, q: f64, gradient: &mut [f64; 2]) -> f64 {
    gradient[0] = 2.0 * p;
    gradient[1] = 2.0 * q;
    let magnitude = (gradient[0] * gradient[0] + gradient[1] * gradient[1]).sqrt();
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    magnitude
}

fn gradient_h(gradient: &mut [f64; 2]) -> f64 {
    let magnitude = 26.0_f64.sqrt();
    gradient[0] = 1.0 / magnitude;
    gradient[1] = -5.0 / magnitude;
    magnitude
}

fn second_gradient_f(p: f64, q: f64, pi_r: f64, pi_i: f64, result: &mut [f64; 2]) {
    let p_inv = 1.0 / (p + 1.0);
    let q_inv = 1.0 / (q + 1.0);
    let p_term = p_inv - pi_r;
    let q_term = q_inv - pi_i;
    let magnitude = (p_term * p_term + q_term * q_term).sqrt();
    result[0] = -p_inv * p_inv * p_term / magnitude;
    result[1] = -q_inv * q_inv * q_term / magnitude;
}

fn make_orthogonal(modified: &mut [f64; 2], fixed: &[f64; 2]) -> f64 {
    let dot = modified[0] * fixed[0] + modified[1] * fixed[1];
    modified[0] -= dot * fixed[0];
    modified[1] -= dot * fixed[1];
    let length = (modified[0] * modified[0] + modified[1] * modified[1]).sqrt();
    modified[0] /= length;
    modified[1] /= length;
    if 1.0 - dot * dot < 0.0 { return 0.0; }
    (1.0 - dot * dot).sqrt()
}

fn optimize_one(p: &mut f64, q: &mut f64, pi_r: f64, pi_i: f64) {
    let mut grad_f = [0.0; 2];
    let mut grad_g = [0.0; 2];
    let mut grad_h = [0.0; 2];
    let mut dd_grad_f = [0.0; 2];
    let h = find_h(*p, *q);
    if h.abs() > H_EPSILON {
        let magnitude = gradient_h(&mut grad_h);
        let total = h / magnitude;
        *p -= total * grad_h[0];
        *q -= total * grad_h[1];
    }
    let g = find_g(*p, *q);
    if g > G_EPSILON {
        let mut magnitude = gradient_g(*p, *q, &mut grad_g);
        gradient_h(&mut grad_h);
        magnitude *= make_orthogonal(&mut grad_g, &grad_h);
        let total = g / magnitude;
        *p -= total * grad_g[0];
        *q -= total * grad_g[1];
    }
    let mut magnitude = gradient_f(*p, *q, pi_r, pi_i, &mut grad_f);
    second_gradient_f(*p, *q, pi_r, pi_i, &mut dd_grad_f);
    let mut total = grad_f[0] * dd_grad_f[0] + grad_f[1] * dd_grad_f[1];
    magnitude /= total.abs();
    gradient_h(&mut grad_h);
    magnitude *= make_orthogonal(&mut grad_f, &grad_h);
    gradient_g(*p, *q, &mut grad_g);
    total = grad_f[0] * grad_g[0] + grad_f[1] * grad_g[1];
    if total > 0.0 {
        let max_dist = -find_g(*p, *q) / total;
        if magnitude > max_dist { magnitude = max_dist; }
    }
    *p += magnitude * grad_f[0];
    *q += magnitude * grad_f[1];
}

fn solve_voltage(p: &mut f64, q: &mut f64, resistance: f64, reactance: f64,
                 alpha: &mut f64, beta: &mut f64) {
    let mut a = resistance * resistance + reactance * reactance;
    let mut b = 2.0 * resistance * reactance * *q - 2.0 * reactance * reactance * *p - resistance;
    let mut c = resistance * *q - reactance * *p;
    c = c * c + resistance * *p;
    let root = (-b - (b * b - 4.0 * a * c).sqrt()) / (2.0 * a);
    *q += ((root - *p) * reactance) / resistance;
    *p = root;
    a = 2.0 * resistance * *p;
    b = 2.0 * reactance * *q;
    *alpha = a / (1.0 - a - b);
    *beta = b / (1.0 - a - b);
}

#[no_mangle]
pub unsafe extern "C" fn olden_power(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let leaves_value = *input;
    let passes_value = *input.add(1);
    if !(1..=MAX_LEAVES).contains(&leaves_value) || !(0..=MAX_PASSES).contains(&passes_value) { return -1; }
    let leaves = leaves_value as usize;
    let passes = passes_value as usize;
    let mut leaf_p = [1.0; MAX_LEAVES as usize];
    let mut leaf_q = [1.0; MAX_LEAVES as usize];
    let mut branch_alpha = 0.0;
    let mut branch_beta = 0.0;
    let mut lateral_alpha = 0.0;
    let mut lateral_beta = 0.0;
    let theta_r = 0.8;
    let theta_i = 0.16;
    let mut work_count = 0_i64;
    for _ in 0..passes {
        let lateral_pi_r = theta_r + lateral_alpha * (theta_r + (theta_i * 0.000001) / (1.0 / 300000.0));
        let lateral_pi_i = theta_i + lateral_beta * (theta_i + (theta_r * (1.0 / 300000.0)) / 0.000001);
        let branch_pi_r = lateral_pi_r + branch_alpha * (theta_r + (theta_i * 0.00002) / 0.0001);
        let branch_pi_i = lateral_pi_i + branch_beta * (theta_i + (theta_r * 0.0001) / 0.00002);
        let mut branch_p = 0.0;
        let mut branch_q = 0.0;
        for leaf in 0..leaves {
            optimize_one(&mut leaf_p[leaf], &mut leaf_q[leaf], branch_pi_r, branch_pi_i);
            if leaf_p[leaf] < 0.0 { leaf_p[leaf] = 0.0; leaf_q[leaf] = 0.0; }
            branch_p += leaf_p[leaf];
            branch_q += leaf_q[leaf];
            work_count += 1;
        }
        solve_voltage(&mut branch_p, &mut branch_q, 0.0001, 0.00002, &mut branch_alpha, &mut branch_beta);
        let mut lateral_p = branch_p;
        let mut lateral_q = branch_q;
        solve_voltage(&mut lateral_p, &mut lateral_q, 1.0 / 300000.0, 0.000001, &mut lateral_alpha, &mut lateral_beta);
    }
    let mut state_projection = 0_i64;
    for leaf in 0..leaves {
        state_projection += (leaf_p[leaf] * 1000.0 + 0.5).floor() as i64;
        state_projection += 2 * (leaf_q[leaf] * 1000.0 + 0.5).floor() as i64;
    }
    state_projection += (branch_alpha * 1000.0 + 0.5).floor() as i64;
    state_projection += 2 * (branch_beta * 1000.0 + 0.5).floor() as i64;
    state_projection += (lateral_alpha * 1000.0 + 0.5).floor() as i64;
    state_projection += 2 * (lateral_beta * 1000.0 + 0.5).floor() as i64;
    state_projection + work_count
}
