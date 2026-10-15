module beaufort_cipher;

fn long beaufort_cipher(long* input, usz length, char* output, usz output_capacity)
		@export("beaufort_cipher") {
	if (input == null || length < 3 || length > 2051) return -1;
	long mode = input[0], text_length_value = input[1], key_length_value = input[2];
	if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 1024
		|| key_length_value < 0 || key_length_value > 1024) return -1;
	usz text_length = (usz)text_length_value, key_length = (usz)key_length_value;
	if (length != 3 + text_length + key_length || (text_length == 0 && key_length != 0)
		|| (text_length != 0 && (key_length == 0 || key_length > text_length))) return -1;
	usz key_start = 3 + text_length;
	for (usz i = 0; i < text_length; i++) {
		long value = input[3 + i];
		if (value != ' ' && (value < 'A' || value > 'Z')) return -1;
	}
	for (usz i = 0; i < key_length; i++) if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
	if (output_capacity < text_length || (text_length != 0 && output == null)) return -2;
	usz key_index = 0;
	for (usz i = 0; i < text_length; i++) {
		long value = input[3 + i];
		if (value == ' ') { output[i] = ' '; continue; }
		long letter = value - 'A';
		long key_letter = input[key_start + key_index % key_length] - 'A';
		long mapped = mode == 0 ? (letter - key_letter + 26) % 26 : (letter + key_letter) % 26;
		output[i] = (char)('A' + mapped);
		key_index++;
	}
	return (long)text_length;
}
