module olden_power;
import "math";

const long MAX_LEAVES = 4;
const long MAX_PASSES = 4;
const double G_EPSILON = 0.000001;
const double H_EPSILON = 0.000001;

fn double find_g(double p, double q) { return p * p + q * q - 0.8; }
fn double find_h(double p, double q) { return p - 5.0 * q; }

fn double gradient_f(double p, double q, double pi_r, double pi_i, double* gradient) {
    gradient[0] = 1.0 / (1.0 + p) - pi_r;
    gradient[1] = 1.0 / (1.0 + q) - pi_i;
    double magnitude = math.sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1]);
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    return magnitude;
}

fn double gradient_g(double p, double q, double* gradient) {
    gradient[0] = 2.0 * p;
    gradient[1] = 2.0 * q;
    double magnitude = math.sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1]);
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    return magnitude;
}

fn double gradient_h(double* gradient) {
    gradient[0] = 1.0 / math.sqrt(26.0);
    gradient[1] = -5.0 / math.sqrt(26.0);
    return math.sqrt(26.0);
}

fn void second_gradient_f(double p, double q, double pi_r, double pi_i, double* result) {
    double p_inv = 1.0 / (p + 1.0), q_inv = 1.0 / (q + 1.0);
    double p_term = p_inv - pi_r, q_term = q_inv - pi_i;
    double magnitude = math.sqrt(p_term * p_term + q_term * q_term);
    result[0] = -p_inv * p_inv * p_term / magnitude;
    result[1] = -q_inv * q_inv * q_term / magnitude;
}

fn double make_orthogonal(double* mod, double* fixed) {
    double dot = mod[0] * fixed[0] + mod[1] * fixed[1];
    mod[0] -= dot * fixed[0];
    mod[1] -= dot * fixed[1];
    double length = math.sqrt(mod[0] * mod[0] + mod[1] * mod[1]);
    mod[0] /= length;
    mod[1] /= length;
    if (1.0 - dot * dot < 0.0) return 0.0;
    return math.sqrt(1.0 - dot * dot);
}

fn void optimize_one(double* p, double* q, double pi_r, double pi_i) {
    double grad_f[2], grad_g[2], grad_h[2], dd_grad_f[2];
    double h = find_h(p[0], q[0]);
    if (math.abs(h) > H_EPSILON) {
        double magnitude = gradient_h(&grad_h[0]);
        double total = h / magnitude;
        p[0] -= total * grad_h[0];
        q[0] -= total * grad_h[1];
    }
    double g = find_g(p[0], q[0]);
    if (g > G_EPSILON) {
        double magnitude = gradient_g(p[0], q[0], &grad_g[0]);
        gradient_h(&grad_h[0]);
        magnitude *= make_orthogonal(&grad_g[0], &grad_h[0]);
        double total = g / magnitude;
        p[0] -= total * grad_g[0];
        q[0] -= total * grad_g[1];
    }
    double magnitude = gradient_f(p[0], q[0], pi_r, pi_i, &grad_f[0]);
    second_gradient_f(p[0], q[0], pi_r, pi_i, &dd_grad_f[0]);
    double total = grad_f[0] * dd_grad_f[0] + grad_f[1] * dd_grad_f[1];
    magnitude /= math.abs(total);
    gradient_h(&grad_h[0]);
    magnitude *= make_orthogonal(&grad_f[0], &grad_h[0]);
    gradient_g(p[0], q[0], &grad_g[0]);
    total = grad_f[0] * grad_g[0] + grad_f[1] * grad_g[1];
    if (total > 0.0) {
        double max_dist = -find_g(p[0], q[0]) / total;
        if (magnitude > max_dist) magnitude = max_dist;
    }
    p[0] += magnitude * grad_f[0];
    q[0] += magnitude * grad_f[1];
}

fn void solve_voltage(double* p, double* q, double resistance, double reactance, double* alpha, double* beta) {
    double a = resistance * resistance + reactance * reactance;
    double b = 2.0 * resistance * reactance * q[0] - 2.0 * reactance * reactance * p[0] - resistance;
    double c = resistance * q[0] - reactance * p[0];
    c = c * c + resistance * p[0];
    double root = (-b - math.sqrt(b * b - 4.0 * a * c)) / (2.0 * a);
    q[0] += ((root - p[0]) * reactance) / resistance;
    p[0] = root;
    a = 2.0 * resistance * p[0];
    b = 2.0 * reactance * q[0];
    alpha[0] = a / (1.0 - a - b);
    beta[0] = b / (1.0 - a - b);
}

fn long olden_power(long* input, usz length) @export("olden_power") {
    if (input == null || length != 2) return -1;
    long leaves_value = input[0], passes_value = input[1];
    if (leaves_value < 1 || leaves_value > MAX_LEAVES || passes_value < 0 || passes_value > MAX_PASSES) return -1;
    int leaves = (int)leaves_value, passes = (int)passes_value;
    double leaf_p[4] = {1.0, 1.0, 1.0, 1.0};
    double leaf_q[4] = {1.0, 1.0, 1.0, 1.0};
    double branch_alpha = 0.0, branch_beta = 0.0, lateral_alpha = 0.0, lateral_beta = 0.0;
    const double theta_r = 0.8, theta_i = 0.16;
    long work_count = 0;
    for (int pass = 0; pass < passes; pass++) {
        double lateral_pi_r = theta_r + lateral_alpha * (theta_r + (theta_i * 0.000001) / (1.0 / 300000.0));
        double lateral_pi_i = theta_i + lateral_beta * (theta_i + (theta_r * (1.0 / 300000.0)) / 0.000001);
        double branch_pi_r = lateral_pi_r + branch_alpha * (theta_r + (theta_i * 0.00002) / 0.0001);
        double branch_pi_i = lateral_pi_i + branch_beta * (theta_i + (theta_r * 0.0001) / 0.00002);
        double branch_p = 0.0, branch_q = 0.0;
        for (int leaf = 0; leaf < leaves; leaf++) {
            optimize_one(&leaf_p[leaf], &leaf_q[leaf], branch_pi_r, branch_pi_i);
            if (leaf_p[leaf] < 0.0) { leaf_p[leaf] = 0.0; leaf_q[leaf] = 0.0; }
            branch_p += leaf_p[leaf];
            branch_q += leaf_q[leaf];
            work_count++;
        }
        solve_voltage(&branch_p, &branch_q, 0.0001, 0.00002, &branch_alpha, &branch_beta);
        double lateral_p = branch_p, lateral_q = branch_q;
        solve_voltage(&lateral_p, &lateral_q, 1.0 / 300000.0, 0.000001, &lateral_alpha, &lateral_beta);
    }
    long state_projection = 0;
    for (int leaf = 0; leaf < leaves; leaf++) {
        state_projection += (long)math.floor(leaf_p[leaf] * 1000.0 + 0.5);
        state_projection += 2 * (long)math.floor(leaf_q[leaf] * 1000.0 + 0.5);
    }
    state_projection += (long)math.floor(branch_alpha * 1000.0 + 0.5);
    state_projection += 2 * (long)math.floor(branch_beta * 1000.0 + 0.5);
    state_projection += (long)math.floor(lateral_alpha * 1000.0 + 0.5);
    state_projection += 2 * (long)math.floor(lateral_beta * 1000.0 + 0.5);
    return state_projection + work_count;
}
