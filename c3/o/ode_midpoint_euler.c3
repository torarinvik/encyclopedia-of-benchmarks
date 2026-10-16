module ode_midpoint_euler;

const usz OUTPUT_BYTES = 16;
const long MAX_STEPS = 8;

fn void put_f64_le(double value, char* output, usz offset) {
	ulong bits = @bitcast(ulong, value);
	for (usz byte = 0; byte < 8; byte++) {
		output[offset + byte] = (char)(bits & 255);
		bits >>= 8;
	}
}

fn long ode_midpoint_euler(long* input, usz length, char* output, usz capacity)
		@export("ode_midpoint_euler") {
	if (input == null || length != 4) return -1;
	long steps = input[0], dt_quarters = input[1], u0 = input[2], v0 = input[3];
	if (steps < 1 || steps > MAX_STEPS || dt_quarters < 1 || dt_quarters > 4 ||
		u0 < -10 || u0 > 10 || v0 < -10 || v0 > 10) return -1;
	if (output == null || capacity < OUTPUT_BYTES) return -2;

	double dt = (double)dt_quarters / 4.0;
	double half_dt = 0.5 * dt;
	double u = (double)u0, v = (double)v0;
	for (long step = 0; step < steps; step++) {
		double midpoint_u = u + half_dt * v;
		double midpoint_v = v - half_dt * u;
		double next_u = u + dt * midpoint_v;
		double next_v = v - dt * midpoint_u;
		u = next_u;
		v = next_v;
	}
	put_f64_le(u, output, 0);
	put_f64_le(v, output, 8);
	return (long)OUTPUT_BYTES;
}
