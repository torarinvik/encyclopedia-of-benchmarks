package olden_power

import "core:c"
import "core:math"

MAX_LEAVES :: 4
MAX_PASSES :: 4
G_EPSILON :: 0.000001
H_EPSILON :: 0.000001

find_g :: proc "contextless" (p, q: f64) -> f64 { return p*p + q*q - 0.8 }
find_h :: proc "contextless" (p, q: f64) -> f64 { return p - 5.0*q }

gradient_f :: proc "contextless" (p, q, pi_r, pi_i: f64, gradient: ^[2]f64) -> f64 {
    gradient[0] = 1.0/(1.0+p) - pi_r
    gradient[1] = 1.0/(1.0+q) - pi_i
    magnitude := math.sqrt(gradient[0]*gradient[0] + gradient[1]*gradient[1])
    gradient[0] /= magnitude
    gradient[1] /= magnitude
    return magnitude
}

gradient_g :: proc "contextless" (p, q: f64, gradient: ^[2]f64) -> f64 {
    gradient[0] = 2.0*p
    gradient[1] = 2.0*q
    magnitude := math.sqrt(gradient[0]*gradient[0] + gradient[1]*gradient[1])
    gradient[0] /= magnitude
    gradient[1] /= magnitude
    return magnitude
}

gradient_h :: proc "contextless" (gradient: ^[2]f64) -> f64 {
    magnitude := math.sqrt(26.0)
    gradient[0] = 1.0/magnitude
    gradient[1] = -5.0/magnitude
    return magnitude
}

second_gradient_f :: proc "contextless" (p, q, pi_r, pi_i: f64, result: ^[2]f64) {
    p_inv := 1.0/(p+1.0)
    q_inv := 1.0/(q+1.0)
    p_term := p_inv-pi_r
    q_term := q_inv-pi_i
    magnitude := math.sqrt(p_term*p_term + q_term*q_term)
    result[0] = -p_inv*p_inv*p_term/magnitude
    result[1] = -q_inv*q_inv*q_term/magnitude
}

make_orthogonal :: proc "contextless" (modified: ^[2]f64, fixed: ^[2]f64) -> f64 {
    dot := modified[0]*fixed[0] + modified[1]*fixed[1]
    modified[0] -= dot*fixed[0]
    modified[1] -= dot*fixed[1]
    length := math.sqrt(modified[0]*modified[0] + modified[1]*modified[1])
    modified[0] /= length
    modified[1] /= length
    if 1.0-dot*dot < 0.0 do return 0.0
    return math.sqrt(1.0-dot*dot)
}

optimize_one :: proc "contextless" (p, q: ^f64, pi_r, pi_i: f64) {
    grad_f: [2]f64
    grad_g: [2]f64
    grad_h: [2]f64
    dd_grad_f: [2]f64
    h := find_h(p^, q^)
    if math.abs(h) > H_EPSILON {
        magnitude := gradient_h(&grad_h)
        total := h/magnitude
        p^ -= total*grad_h[0]
        q^ -= total*grad_h[1]
    }
    g := find_g(p^, q^)
    if g > G_EPSILON {
        magnitude := gradient_g(p^, q^, &grad_g)
        _ = gradient_h(&grad_h)
        magnitude *= make_orthogonal(&grad_g, &grad_h)
        total := g/magnitude
        p^ -= total*grad_g[0]
        q^ -= total*grad_g[1]
    }
    magnitude := gradient_f(p^, q^, pi_r, pi_i, &grad_f)
    second_gradient_f(p^, q^, pi_r, pi_i, &dd_grad_f)
    total := grad_f[0]*dd_grad_f[0] + grad_f[1]*dd_grad_f[1]
    magnitude /= math.abs(total)
    _ = gradient_h(&grad_h)
    magnitude *= make_orthogonal(&grad_f, &grad_h)
    _ = gradient_g(p^, q^, &grad_g)
    total = grad_f[0]*grad_g[0] + grad_f[1]*grad_g[1]
    if total > 0.0 {
        max_dist := -find_g(p^, q^)/total
        if magnitude > max_dist do magnitude = max_dist
    }
    p^ += magnitude*grad_f[0]
    q^ += magnitude*grad_f[1]
}

solve_voltage :: proc "contextless" (p, q: ^f64, resistance, reactance: f64, alpha, beta: ^f64) {
    a := resistance*resistance + reactance*reactance
    b := 2.0*resistance*reactance*q^ - 2.0*reactance*reactance*p^ - resistance
    c0 := resistance*q^ - reactance*p^
    c0 = c0*c0 + resistance*p^
    root := (-b-math.sqrt(b*b-4.0*a*c0))/(2.0*a)
    q^ += ((root-p^)*reactance)/resistance
    p^ = root
    a = 2.0*resistance*p^
    b = 2.0*reactance*q^
    alpha^ = a/(1.0-a-b)
    beta^ = b/(1.0-a-b)
}

@(export)
olden_power :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 2 do return -1
    if input[0] < 1 || input[0] > MAX_LEAVES || input[1] < 0 || input[1] > MAX_PASSES do return -1
    leaves := int(input[0])
    passes := int(input[1])
    leaf_p: [MAX_LEAVES]f64 = {1.0, 1.0, 1.0, 1.0}
    leaf_q: [MAX_LEAVES]f64 = {1.0, 1.0, 1.0, 1.0}
    branch_alpha, branch_beta: f64 = 0.0, 0.0
    lateral_alpha, lateral_beta: f64 = 0.0, 0.0
    theta_r: f64 = 0.8
    theta_i: f64 = 0.16
    work_count: i64 = 0
    for _ in 0..<passes {
        lateral_pi_r := theta_r + lateral_alpha*(theta_r + (theta_i*0.000001)/(1.0/300000.0))
        lateral_pi_i := theta_i + lateral_beta*(theta_i + (theta_r*(1.0/300000.0))/0.000001)
        branch_pi_r := lateral_pi_r + branch_alpha*(theta_r + (theta_i*0.00002)/0.0001)
        branch_pi_i := lateral_pi_i + branch_beta*(theta_i + (theta_r*0.0001)/0.00002)
        branch_p, branch_q: f64 = 0.0, 0.0
        for leaf in 0..<leaves {
            optimize_one(&leaf_p[leaf], &leaf_q[leaf], branch_pi_r, branch_pi_i)
            if leaf_p[leaf] < 0.0 { leaf_p[leaf] = 0.0; leaf_q[leaf] = 0.0 }
            branch_p += leaf_p[leaf]
            branch_q += leaf_q[leaf]
            work_count += 1
        }
        solve_voltage(&branch_p, &branch_q, 0.0001, 0.00002, &branch_alpha, &branch_beta)
        lateral_p, lateral_q := branch_p, branch_q
        solve_voltage(&lateral_p, &lateral_q, 1.0/300000.0, 0.000001, &lateral_alpha, &lateral_beta)
    }
    state_projection: i64 = 0
    for leaf in 0..<leaves {
        state_projection += i64(math.floor(leaf_p[leaf]*1000.0 + 0.5))
        state_projection += 2*i64(math.floor(leaf_q[leaf]*1000.0 + 0.5))
    }
    state_projection += i64(math.floor(branch_alpha*1000.0 + 0.5))
    state_projection += 2*i64(math.floor(branch_beta*1000.0 + 0.5))
    state_projection += i64(math.floor(lateral_alpha*1000.0 + 0.5))
    state_projection += 2*i64(math.floor(lateral_beta*1000.0 + 0.5))
    return state_projection + work_count
}
