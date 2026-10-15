module word_count_julia;

fn char lower_byte(long* input, usz index) {
	char byte = (char)input[index];
	if (byte >= 'A' && byte <= 'Z') return (char)(byte + ('a' - 'A'));
	return byte;
}

fn bool is_word_byte(char byte) {
	return (byte >= 'a' && byte <= 'z') || (byte >= '0' && byte <= '9') || byte == '_';
}

fn int compare_word(long* input, usz start, usz length,
		usz* starts, usz* lengths, usz slot) {
	usz shared = length < lengths[slot] ? length : lengths[slot];
	for (usz offset = 0; offset < shared; offset++) {
		char left = lower_byte(input, start + offset);
		char right = lower_byte(input, starts[slot] + offset);
		if (left < right) return -1;
		if (left > right) return 1;
	}
	if (length < lengths[slot]) return -1;
	if (length > lengths[slot]) return 1;
	return 0;
}

fn usz write_count(char* output, usz position, usz count) {
	char digits[4];
	usz digit_count = 0;
	do {
		digits[digit_count++] = (char)('0' + count % 10);
		count /= 10;
	} while (count != 0);
	output[position++] = '=';
	while (digit_count != 0) output[position++] = digits[--digit_count];
	output[position++] = '\n';
	return position;
}

fn long word_count_julia(long* input, usz length, char* output, usz output_capacity)
		@export("word_count_julia") {
	if (length > 1000 || (length != 0 && input == null)) return -1;
	for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 127) return -1;
	usz starts[1000];
	usz lengths[1000];
	usz counts[1000];
	usz unique_count = 0, index = 0;
	while (index < length) {
		if (!is_word_byte(lower_byte(input, index))) { index++; continue; }
		usz start = index;
		while (index < length && is_word_byte(lower_byte(input, index))) index++;
		usz token_length = index - start;
		if (index + 1 < length && input[index] == 39 && is_word_byte(lower_byte(input, index + 1))) {
			token_length += 2;
			index += 2;
		}
		usz position = 0;
		while (position < unique_count && compare_word(input, start, token_length, starts, lengths, position) > 0) position++;
		if (position < unique_count && compare_word(input, start, token_length, starts, lengths, position) == 0) {
			counts[position]++;
		} else {
			for (usz move = unique_count; move > position; move--) {
				starts[move] = starts[move - 1];
				lengths[move] = lengths[move - 1];
				counts[move] = counts[move - 1];
			}
			starts[position] = start; lengths[position] = token_length; counts[position] = 1;
			unique_count++;
		}
	}
	usz required = 0;
	for (usz item = 0; item < unique_count; item++) {
		usz digits = 1;
		for (usz value = counts[item]; value >= 10; value /= 10) digits++;
		required += lengths[item] + digits + 2;
	}
	if (output_capacity < required || (required != 0 && output == null)) return -2;
	usz written = 0;
	for (usz item = 0; item < unique_count; item++) {
		for (usz offset = 0; offset < lengths[item]; offset++) output[written++] = lower_byte(input, starts[item] + offset);
		written = write_count(output, written, counts[item]);
	}
	return (long)written;
}
