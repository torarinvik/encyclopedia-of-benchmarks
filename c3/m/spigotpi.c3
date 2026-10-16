module spigotpi;

const usz MAX_DIGITS = 256;
const usz MAX_BOXES = 854;

fn long spigotpi(long* input, usz length, char* output, usz output_capacity)
		@export("spigotpi") {
	if (length != 1 || input == null || input[0] < 0 || input[0] > (long)MAX_DIGITS) return -1;
	usz digit_count = (usz)input[0];
	if (output == null || output_capacity < digit_count) return -2;
	if (digit_count == 0) return 0;

	usz boxes = digit_count * 10 / 3;
	long remainders[MAX_BOXES] = {0};
	for (usz item = 0; item < boxes; item++) remainders[item] = 2;
	usz digits_held = 0;
	for (usz index = 0; index < digit_count; index++) {
		long carried_over = 0, sum = 0;
		usz cursor = boxes;
		while (cursor > 0) {
			usz j = --cursor;
			remainders[j] *= 10;
			sum = remainders[j] + carried_over;
			long denominator = (long)(j * 2 + 1);
			long quotient = sum / denominator;
			remainders[j] = sum % denominator;
			carried_over = quotient * (long)j;
		}
		remainders[0] = sum % 10;
		long q = sum / 10;
		if (q == 9) {
			digits_held++;
		} else if (q == 10) {
			q = 0;
			for (usz offset = 1; offset <= digits_held; offset++) {
				usz position = index - offset;
				if (output[position] == '9') output[position] = '0';
				else output[position]++;
			}
			digits_held = 1;
		} else {
			digits_held = 1;
		}
		output[index] = (char)('0' + q);
	}
	return (long)digit_count;
}
