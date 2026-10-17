package simple_pendulum_rk4

import "core:c"
import "core:math"

@(export)
simple_pendulum_rk4 :: proc "c" (values: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length != c.size_t(5) do return -1
	minimums := [5]f64{10000.0, 100000.0, -3141593.0, -100000000.0, 1.0}
	maximums := [5]f64{100000000.0, 20000000.0, 3141593.0, 100000000.0, 100000.0}
	for i := 0; i < 5; i += 1 {
		if values[i] != values[i] || math.floor(values[i]) != values[i] ||
			values[i] < minimums[i] || values[i] > maximums[i] do return -1
	}

	length_m := values[0] / 1000000.0
	gravity := values[1] / 1000000.0
	theta := values[2] / 1000000.0
	omega := values[3] / 1000000.0
	dt := values[4] / 1000000.0
	scale := gravity / length_m

	k1_theta := omega
	k1_omega := -scale * math.sin(theta)
	k2_theta := omega + 0.5 * dt * k1_omega
	k2_omega := -scale * math.sin(theta + 0.5 * dt * k1_theta)
	k3_theta := omega + 0.5 * dt * k2_omega
	k3_omega := -scale * math.sin(theta + 0.5 * dt * k2_theta)
	k4_theta := omega + dt * k3_omega
	k4_omega := -scale * math.sin(theta + dt * k3_theta)
	theta_next := theta + dt / 6.0 * (k1_theta + 2.0 * k2_theta + 2.0 * k3_theta + k4_theta)
	omega_next := omega + dt / 6.0 * (k1_omega + 2.0 * k2_omega + 2.0 * k3_omega + k4_omega)

	if output == nil || capacity < c.size_t(2) do return -2
	output[0], output[1] = theta_next, omega_next
	return 2
}
