module main

import math

const max_leaves = 4
const max_passes = 4
const g_epsilon = 0.000001
const h_epsilon = 0.000001

fn find_g(p f64, q f64) f64 { return p * p + q * q - 0.8 }
fn find_h(p f64, q f64) f64 { return p - 5.0 * q }

fn gradient_f(p f64, q f64, pi_r f64, pi_i f64, mut gradient [2]f64) f64 {
	gradient[0] = 1.0 / (1.0 + p) - pi_r
	gradient[1] = 1.0 / (1.0 + q) - pi_i
	magnitude := math.sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1])
	gradient[0] /= magnitude
	gradient[1] /= magnitude
	return magnitude
}

fn gradient_g(p f64, q f64, mut gradient [2]f64) f64 {
	gradient[0] = 2.0 * p
	gradient[1] = 2.0 * q
	magnitude := math.sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1])
	gradient[0] /= magnitude
	gradient[1] /= magnitude
	return magnitude
}

fn gradient_h(mut gradient [2]f64) f64 {
	magnitude := math.sqrt(26.0)
	gradient[0] = 1.0 / magnitude
	gradient[1] = -5.0 / magnitude
	return magnitude
}

fn second_gradient_f(p f64, q f64, pi_r f64, pi_i f64, mut result [2]f64) {
	p_inv := 1.0 / (p + 1.0)
	q_inv := 1.0 / (q + 1.0)
	p_term := p_inv - pi_r
	q_term := q_inv - pi_i
	magnitude := math.sqrt(p_term * p_term + q_term * q_term)
	result[0] = -p_inv * p_inv * p_term / magnitude
	result[1] = -q_inv * q_inv * q_term / magnitude
}

fn make_orthogonal(mut modified [2]f64, fixed [2]f64) f64 {
	dot := modified[0] * fixed[0] + modified[1] * fixed[1]
	modified[0] -= dot * fixed[0]
	modified[1] -= dot * fixed[1]
	length := math.sqrt(modified[0] * modified[0] + modified[1] * modified[1])
	modified[0] /= length
	modified[1] /= length
	if 1.0 - dot * dot < 0.0 { return 0.0 }
	return math.sqrt(1.0 - dot * dot)
}

fn optimize_one(p f64, q f64, pi_r f64, pi_i f64) [2]f64 {
	mut grad_f := [2]f64{}
	mut grad_g := [2]f64{}
	mut grad_h := [2]f64{}
	mut dd_grad_f := [2]f64{}
	h := find_h(p, q)
	mut current_p := p
	mut current_q := q
	if math.abs(h) > h_epsilon {
		magnitude := gradient_h(mut grad_h)
		total := h / magnitude
		current_p -= total * grad_h[0]
		current_q -= total * grad_h[1]
	}
	g := find_g(current_p, current_q)
	if g > g_epsilon {
		mut magnitude := gradient_g(current_p, current_q, mut grad_g)
		_ = gradient_h(mut grad_h)
		magnitude *= make_orthogonal(mut grad_g, grad_h)
		total := g / magnitude
		current_p -= total * grad_g[0]
		current_q -= total * grad_g[1]
	}
	mut magnitude := gradient_f(current_p, current_q, pi_r, pi_i, mut grad_f)
	second_gradient_f(current_p, current_q, pi_r, pi_i, mut dd_grad_f)
	mut total := grad_f[0] * dd_grad_f[0] + grad_f[1] * dd_grad_f[1]
	magnitude /= math.abs(total)
	_ = gradient_h(mut grad_h)
	magnitude *= make_orthogonal(mut grad_f, grad_h)
	_ = gradient_g(current_p, current_q, mut grad_g)
	total = grad_f[0] * grad_g[0] + grad_f[1] * grad_g[1]
	if total > 0.0 {
		max_dist := -find_g(current_p, current_q) / total
		if magnitude > max_dist { magnitude = max_dist }
	}
	current_p += magnitude * grad_f[0]
	current_q += magnitude * grad_f[1]
	return [2]f64{current_p, current_q}
}

fn solve_voltage(p f64, q f64, resistance f64, reactance f64, mut coeff [2]f64) [2]f64 {
	a := resistance * resistance + reactance * reactance
	b := 2.0 * resistance * reactance * q - 2.0 * reactance * reactance * p - resistance
	mut c := resistance * q - reactance * p
	c = c * c + resistance * p
	root := (-b - math.sqrt(b * b - 4.0 * a * c)) / (2.0 * a)
	new_q := q + ((root - p) * reactance) / resistance
	new_p := root
	a2 := 2.0 * resistance * new_p
	b2 := 2.0 * reactance * new_q
	coeff[0] = a2 / (1.0 - a2 - b2)
	coeff[1] = b2 / (1.0 - a2 - b2)
	return [2]f64{new_p, new_q}
}

@[export: 'olden_power']
pub fn olden_power(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	leaves_value := unsafe { input[0] }
	passes_value := unsafe { input[1] }
	if leaves_value < 1 || leaves_value > max_leaves || passes_value < 0 || passes_value > max_passes { return -1 }
	leaves := int(leaves_value)
	passes := int(passes_value)
	mut leaf_p := [4]f64{1.0, 1.0, 1.0, 1.0}
	mut leaf_q := [4]f64{1.0, 1.0, 1.0, 1.0}
	mut branch_coeff := [2]f64{}
	mut lateral_coeff := [2]f64{}
	theta_r := 0.8
	theta_i := 0.16
	mut work_count := i64(0)
	for _ in 0 .. passes {
		lateral_pi_r := theta_r + lateral_coeff[0] * (theta_r + (theta_i * 0.000001) / (1.0 / 300000.0))
		lateral_pi_i := theta_i + lateral_coeff[1] * (theta_i + (theta_r * (1.0 / 300000.0)) / 0.000001)
		branch_pi_r := lateral_pi_r + branch_coeff[0] * (theta_r + (theta_i * 0.00002) / 0.0001)
		branch_pi_i := lateral_pi_i + branch_coeff[1] * (theta_i + (theta_r * 0.0001) / 0.00002)
		mut branch_p := f64(0.0)
		mut branch_q := f64(0.0)
		for leaf in 0 .. leaves {
			updated := optimize_one(leaf_p[leaf], leaf_q[leaf], branch_pi_r, branch_pi_i)
			leaf_p[leaf] = updated[0]
			leaf_q[leaf] = updated[1]
			if leaf_p[leaf] < 0.0 { leaf_p[leaf] = 0.0; leaf_q[leaf] = 0.0 }
			branch_p += leaf_p[leaf]
			branch_q += leaf_q[leaf]
			work_count++
		}
		branch := solve_voltage(branch_p, branch_q, 0.0001, 0.00002, mut branch_coeff)
		branch_p, branch_q = branch[0], branch[1]
		mut lateral_p := branch_p
		mut lateral_q := branch_q
		_ = solve_voltage(lateral_p, lateral_q, 1.0 / 300000.0, 0.000001, mut lateral_coeff)
	}
	mut state_projection := i64(0)
	for leaf in 0 .. leaves {
		state_projection += i64(math.floor(leaf_p[leaf] * 1000.0 + 0.5))
		state_projection += 2 * i64(math.floor(leaf_q[leaf] * 1000.0 + 0.5))
	}
	state_projection += i64(math.floor(branch_coeff[0] * 1000.0 + 0.5))
	state_projection += 2 * i64(math.floor(branch_coeff[1] * 1000.0 + 0.5))
	state_projection += i64(math.floor(lateral_coeff[0] * 1000.0 + 0.5))
	state_projection += 2 * i64(math.floor(lateral_coeff[1] * 1000.0 + 0.5))
	return state_projection + work_count
}
