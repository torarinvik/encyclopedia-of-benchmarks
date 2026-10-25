#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LEAVES 4
#define MAX_PASSES 4
#define F_EPSILON 0.000001
#define G_EPSILON 0.000001
#define H_EPSILON 0.000001

static double find_g(double p, double q) { return p * p + q * q - 0.8; }
static double find_h(double p, double q) { return p - 5.0 * q; }

static double gradient_f(double p, double q, double pi_r, double pi_i, double gradient[2]) {
    gradient[0] = 1.0 / (1.0 + p) - pi_r;
    gradient[1] = 1.0 / (1.0 + q) - pi_i;
    double magnitude = sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1]);
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    return magnitude;
}

static double gradient_g(double p, double q, double gradient[2]) {
    gradient[0] = 2.0 * p;
    gradient[1] = 2.0 * q;
    double magnitude = sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1]);
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    return magnitude;
}

static double gradient_h(double gradient[2]) {
    gradient[0] = 1.0;
    gradient[1] = -5.0;
    double magnitude = sqrt(26.0);
    gradient[0] /= magnitude;
    gradient[1] /= magnitude;
    return magnitude;
}

static void second_gradient_f(double p, double q, double pi_r, double pi_i, double result[2]) {
    double p_inv = 1.0 / (p + 1.0), q_inv = 1.0 / (q + 1.0);
    double p_term = p_inv - pi_r, q_term = q_inv - pi_i;
    double magnitude = sqrt(p_term * p_term + q_term * q_term);
    result[0] = -p_inv * p_inv * p_term / magnitude;
    result[1] = -q_inv * q_inv * q_term / magnitude;
}

static double make_orthogonal(double mod[2], const double fixed[2]) {
    double dot = mod[0] * fixed[0] + mod[1] * fixed[1];
    mod[0] -= dot * fixed[0];
    mod[1] -= dot * fixed[1];
    double length = sqrt(mod[0] * mod[0] + mod[1] * mod[1]);
    mod[0] /= length;
    mod[1] /= length;
    if (1.0 - dot * dot < 0.0) return 0.0;
    return sqrt(1.0 - dot * dot);
}

/* One bounded body of the pinned optimize_node do-while recurrence. */
static void optimize_one(double *p, double *q, double pi_r, double pi_i) {
    double grad_f[2], grad_g[2], grad_h[2], dd_grad_f[2];
    double h = find_h(*p, *q);
    if (fabs(h) > H_EPSILON) {
        double magnitude = gradient_h(grad_h);
        double total = h / magnitude;
        *p -= total * grad_h[0];
        *q -= total * grad_h[1];
    }
    double g = find_g(*p, *q);
    if (g > G_EPSILON) {
        double magnitude = gradient_g(*p, *q, grad_g);
        (void)gradient_h(grad_h);
        magnitude *= make_orthogonal(grad_g, grad_h);
        double total = g / magnitude;
        *p -= total * grad_g[0];
        *q -= total * grad_g[1];
    }
    double magnitude = gradient_f(*p, *q, pi_r, pi_i, grad_f);
    second_gradient_f(*p, *q, pi_r, pi_i, dd_grad_f);
    double total = grad_f[0] * dd_grad_f[0] + grad_f[1] * dd_grad_f[1];
    magnitude /= fabs(total);
    (void)gradient_h(grad_h);
    magnitude *= make_orthogonal(grad_f, grad_h);
    (void)gradient_g(*p, *q, grad_g);
    total = grad_f[0] * grad_g[0] + grad_f[1] * grad_g[1];
    if (total > 0.0) {
        double max_dist = -find_g(*p, *q) / total;
        if (magnitude > max_dist) magnitude = max_dist;
    }
    *p += magnitude * grad_f[0];
    *q += magnitude * grad_f[1];
}

static void solve_voltage(double *p, double *q, double resistance, double reactance,
                          double *alpha, double *beta) {
    double a = resistance * resistance + reactance * reactance;
    double b = 2.0 * resistance * reactance * *q - 2.0 * reactance * reactance * *p - resistance;
    double c = resistance * *q - reactance * *p;
    c = c * c + resistance * *p;
    double root = (-b - sqrt(b * b - 4.0 * a * c)) / (2.0 * a);
    *q += ((root - *p) * reactance) / resistance;
    *p = root;
    a = 2.0 * resistance * *p;
    b = 2.0 * reactance * *q;
    *alpha = a / (1.0 - a - b);
    *beta = b / (1.0 - a - b);
}

int64_t olden_power(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    int64_t leaves_value = input[0], passes_value = input[1];
    if (leaves_value < 1 || leaves_value > MAX_LEAVES || passes_value < 0 || passes_value > MAX_PASSES) return -1;
    int leaves = (int)leaves_value, passes = (int)passes_value;
    double leaf_p[MAX_LEAVES] = {1.0, 1.0, 1.0, 1.0};
    double leaf_q[MAX_LEAVES] = {1.0, 1.0, 1.0, 1.0};
    double branch_alpha = 0.0, branch_beta = 0.0;
    double lateral_alpha = 0.0, lateral_beta = 0.0;
    const double theta_r = 0.8, theta_i = 0.16;
    int64_t work_count = 0;

    for (int pass = 0; pass < passes; ++pass) {
        double lateral_pi_r = theta_r + lateral_alpha * (theta_r + (theta_i * 0.000001) / (1.0 / 300000.0));
        double lateral_pi_i = theta_i + lateral_beta * (theta_i + (theta_r * (1.0 / 300000.0)) / 0.000001);
        double branch_pi_r = lateral_pi_r + branch_alpha * (theta_r + (theta_i * 0.00002) / 0.0001);
        double branch_pi_i = lateral_pi_i + branch_beta * (theta_i + (theta_r * 0.0001) / 0.00002);
        double branch_p = 0.0, branch_q = 0.0;
        for (int leaf = 0; leaf < leaves; ++leaf) {
            optimize_one(&leaf_p[leaf], &leaf_q[leaf], branch_pi_r, branch_pi_i);
            if (leaf_p[leaf] < 0.0) { leaf_p[leaf] = 0.0; leaf_q[leaf] = 0.0; }
            branch_p += leaf_p[leaf];
            branch_q += leaf_q[leaf];
            ++work_count;
        }
        solve_voltage(&branch_p, &branch_q, 0.0001, 0.00002, &branch_alpha, &branch_beta);
        double lateral_p = branch_p, lateral_q = branch_q;
        solve_voltage(&lateral_p, &lateral_q, 1.0 / 300000.0, 0.000001, &lateral_alpha, &lateral_beta);
    }
    int64_t state_projection = 0;
    for (int leaf = 0; leaf < leaves; ++leaf) {
        state_projection += (int64_t)floor(leaf_p[leaf] * 1000.0 + 0.5);
        state_projection += 2 * (int64_t)floor(leaf_q[leaf] * 1000.0 + 0.5);
    }
    state_projection += (int64_t)floor(branch_alpha * 1000.0 + 0.5);
    state_projection += 2 * (int64_t)floor(branch_beta * 1000.0 + 0.5);
    state_projection += (int64_t)floor(lateral_alpha * 1000.0 + 0.5);
    state_projection += 2 * (int64_t)floor(lateral_beta * 1000.0 + 0.5);
    return state_projection + work_count;
}
