module vernam_cipher;

const usz MAX_VERNAM_LENGTH = 1024;

fn long vernam_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("vernam_cipher") {
	if (input == null || length < 3 || length > 3 + 2 * MAX_VERNAM_LENGTH) return -1;
	long mode = input[0];
	long text_length_value = input[1];
	long key_length_value = input[2];
	if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > MAX_VERNAM_LENGTH
		|| key_length_value < 1 || key_length_value > MAX_VERNAM_LENGTH) return -1;
	usz text_length = (usz)text_length_value;
	usz key_length = (usz)key_length_value;
	if (length != 3 + text_length + key_length) return -1;
	usz key_start = 3 + text_length;
	for (usz i = 0; i < text_length; i++) if (input[3 + i] < 'A' || input[3 + i] > 'Z') return -1;
	for (usz i = 0; i < key_length; i++) if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
	if (output_capacity < text_length) return -2;

	for (usz i = 0; i < text_length; i++) {
		long text_value = input[3 + i] - 'A';
		long key_value = input[key_start + i % key_length] - 'A';
		long mapped = mode == 0 ? (text_value + key_value) % 26 : (text_value - key_value + 26) % 26;
		output[i] = (char)('A' + mapped);
	}
	return (long)text_length;
}
