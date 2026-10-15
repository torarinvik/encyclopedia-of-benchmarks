pub export fn hill_cipher_mod26_java(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
	if (input == null or length < 1 or length > 257) return -1;
	if (input[0] != 0 and input[0] != 1) return -1;
	const key = if (input[0] == 0) [4]i64{ 3, 3, 2, 5 } else [4]i64{ 15, 17, 20, 9 };
	var text: [256]u8 = undefined; var text_len: usize = 0;
	for (1..length) |index| {
		const raw = input[index]; if (raw < 0 or raw > 127) return -1;
		var character: u8 = @intCast(raw);
		if (character >= 'a' and character <= 'z') character -= 'a' - 'A';
		if (character >= 'A' and character <= 'Z') { text[text_len] = character; text_len += 1; }
	}
	if (text_len % 2 == 1) { text[text_len] = 'X'; text_len += 1; }
	if (text_len > capacity or (text_len > 0 and output == null)) return -2;
	if (text_len == 0) return 0;
	for (0..text_len / 2) |block| {
		const index = block * 2; const a = @as(i64, text[index]) - @as(i64, 'A'); const b = @as(i64, text[index + 1]) - @as(i64, 'A');
		output[index] = @as(u8, 'A') + @as(u8, @intCast((key[0] * a + key[1] * b) % 26));
		output[index + 1] = @as(u8, 'A') + @as(u8, @intCast((key[2] * a + key[3] * b) % 26));
	}
	return @intCast(text_len);
}
