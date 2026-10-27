module pfr_local_forward_decision;

fn void put64(char *out, usz pos, long value) {
	ulong bits = (ulong)value;
	for (usz i = 0; i < 8; i += 1) { out[pos+i] = (char)(bits & 255); bits >>= 8; }
}

long pfr_local_forward_decision(long *input, usz length, char *output, usz capacity) @export("pfr_local_forward_decision") {
	if (input == null || length != 2) return -1;
	long angle = input[0], draw = input[1];
	if (angle < 0 || angle > 180000000 || draw < 0 || draw >= 1000000) return -1;
	long forward = 0;
	if (angle >= 134000000 || 180*draw < angle) forward = 1;
	if (output == null || capacity < 8) return -2;
	put64(output, 0, forward);
	return 8;
}
