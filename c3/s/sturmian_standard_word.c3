module sturmian_standard_word;

const MAX_STEPS: long = 4;
const MAX_REPEAT: long = 2;
const MAX_WORD: usz = 41;

fn bool directives_valid(long* values, usz length, long[MAX_STEPS] directives,
	usz* steps_out) {
	if (values == null || length < 1 || length > 6) return false;
	long steps_word = values[0];
	if (steps_word < 0 || steps_word > MAX_STEPS) return false;
	usz steps = (usz)steps_word;
	if (length != steps + 1) return false;
	for (usz i = 0; i < steps; i += 1) {
		long repeat = values[i + 1];
		if (i == 0) {
			if (repeat < 0 || repeat > MAX_REPEAT) return false;
		} else if (repeat < 1 || repeat > MAX_REPEAT) {
			return false;
		}
		directives[i] = repeat;
	}
	*steps_out = steps;
	return true;
}

fn long sturmian_standard_word(long* values, usz length, char* output,
	usz output_capacity) @export("sturmian_standard_word") {
	long[MAX_STEPS] directives = {0, 0, 0, 0};
	usz steps = 0;
	if (!directives_valid(values, length, directives, &steps)) return -1;

	char[MAX_WORD] first = {0};
	char[MAX_WORD] second = {0};
	char[MAX_WORD] third = {0};
	char* previous = first;
	char* current = second;
	char* following = third;
	usz previous_length = 1;
	usz current_length = 1;
	previous[0] = 'b';
	current[0] = 'a';

	for (usz step = 0; step < steps; step += 1) {
		usz repeat = (usz)directives[step];
		usz following_length = current_length * repeat + previous_length;
		usz position = 0;
		for (usz copy = 0; copy < repeat; copy += 1) {
			for (usz i = 0; i < current_length; i += 1) following[position++] = current[i];
		}
		for (usz i = 0; i < previous_length; i += 1) following[position++] = previous[i];
		for (usz i = 0; i < current_length; i += 1) previous[i] = current[i];
		for (usz i = 0; i < following_length; i += 1) current[i] = following[i];
		previous_length = current_length;
		current_length = following_length;
	}

	if (output == null || output_capacity < current_length) return -2;
	for (usz i = 0; i < current_length; i += 1) output[i] = current[i];
	return (long)current_length;
}
