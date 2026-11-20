module digital_filter_direct_form_ii_transposed;

const usz MAX_SAMPLES = 32;
const usz MAX_ORDER = 4;
const usz MAX_INPUT_WORDS = 45;

fn long digital_filter_direct_form_ii_transposed(long* input, usz length,
	uint8* output, usz capacity) @export("digital_filter_direct_form_ii_transposed") {
	if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
	long sample_word = input[0];
	long order_word = input[1];
	if (sample_word < 0 || sample_word > (long)MAX_SAMPLES || order_word < 0 || order_word > (long)MAX_ORDER) return -1;
	usz count = (usz)sample_word;
	usz order = (usz)order_word;
	if (length != count + 2 * order + 4) return -1;
	usz a_start = 2;
	usz b_start = order + 3;
	usz x_start = 2 * order + 4;
	if (input[a_start] != 1) return -1;
	for (usz i = 1; i <= order; i += 1) if (input[a_start + i] < -1 || input[a_start + i] > 1) return -1;
	for (usz i = 0; i <= order; i += 1) if (input[b_start + i] < -1 || input[b_start + i] > 1) return -1;
	for (usz i = 0; i < count; i += 1) if (input[x_start + i] < -16 || input[x_start + i] > 16) return -1;
	usz bytes = count * 8;
	if (bytes > 0 && (output == null || capacity < bytes)) return -2;
	if (count == 0) return 0;
	long[4] state = {0, 0, 0, 0};
	for (usz index = 0; index < count; index += 1) {
		long sample = input[x_start + index];
		long value = input[b_start] * sample + (order == 0 ? 0 : state[0]);
		for (usz stage = 0; stage < order; stage += 1) {
			long next_state = stage + 1 < order ? state[stage + 1] : 0;
			state[stage] = next_state + input[b_start + stage + 1] * sample - input[a_start + stage + 1] * value;
		}
		ulong bits = (ulong)value;
		for (usz byte = 0; byte < 8; byte += 1) output[index * 8 + byte] = (uint8)(bits >> (8 * byte));
	}
	return (long)bytes;
}
