module porta_cipher;

fn long porta_cipher(long* input, usz length, char* output, usz output_capacity)
		@export("porta_cipher") {
	if (input == null || length < 3 || length > 1091) return -1;
	long mode = input[0], text_value = input[1], key_value = input[2];
	if ((mode != 0 && mode != 1) || text_value < 0 || text_value > 1024 || key_value < 0 || key_value > 64) return -1;
	usz text_length = (usz)text_value, key_length = (usz)key_value;
	if (length != 3 + text_length + key_length || (text_length != 0 && key_length == 0)) return -1;
	usz key_start = 3 + text_length;
	for (usz i = 3; i < length; i++) {
		long value = input[i];
		if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
	}
	if (output_capacity < text_length || (text_length != 0 && output == null)) return -2;
	for (usz i = 0; i < text_length; i++) {
		long letter = input[3 + i], key_letter = input[key_start + i % key_length];
		if (letter >= 'a') letter -= 32;
		if (key_letter >= 'a') key_letter -= 32;
		long letter_index = letter - 'A', group = (key_letter - 'A') / 2;
		long mapped = letter_index < 13 ? 13 + (letter_index + 13 - group) % 13
									: (letter_index - 13 + group) % 13;
		output[i] = (char)('A' + mapped);
	}
	return (long)text_length;
}
