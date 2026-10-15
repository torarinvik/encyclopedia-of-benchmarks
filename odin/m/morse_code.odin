package morse_code

import "core:c"

// Encode ASCII letters and digits as space-separated International Morse.
morse_letter_index :: proc "contextless" (value: i64) -> i64 {
    if value >= 65 && value <= 90 do return value - 65
    if value >= 97 && value <= 122 do return value - 97
    if value >= 48 && value <= 57 do return 26 + value - 48
    return -1
}

morse_word :: proc "contextless" (index: int) -> i64 {
	if index == 0 do return 514
	if index == 1 do return 1031
	if index == 2 do return 1029
	if index == 3 do return 771
	if index == 4 do return 257
	if index == 5 do return 1037
	if index == 6 do return 769
	if index == 7 do return 1039
	if index == 8 do return 515
	if index == 9 do return 1032
	if index == 10 do return 770
	if index == 11 do return 1035
	if index == 12 do return 512
	if index == 13 do return 513
	if index == 14 do return 768
	if index == 15 do return 1033
	if index == 16 do return 1026
	if index == 17 do return 773
	if index == 18 do return 775
	if index == 19 do return 256
	if index == 20 do return 774
	if index == 21 do return 1038
	if index == 22 do return 772
	if index == 23 do return 1030
	if index == 24 do return 1028
	if index == 25 do return 1027
	if index == 26 do return 1280
	if index == 27 do return 1296
	if index == 28 do return 1304
	if index == 29 do return 1308
	if index == 30 do return 1310
	if index == 31 do return 1311
	if index == 32 do return 1295
	if index == 33 do return 1287
	if index == 34 do return 1283
	if index == 35 do return 1281
    return 0
}

@(export)
morse_code :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > c.size_t(682) do return -1
    required := c.size_t(0)
    for index := 0; index < int(length); index += 1 {
        letter := morse_letter_index(input[index])
        if letter < 0 do return -1
        word := morse_word(int(letter))
        required += c.size_t((word / 256) % 8)
        if index != 0 do required += 1
    }
    if output_capacity < required do return -2
    written := c.size_t(0)
    for index := 0; index < int(length); index += 1 {
        if index != 0 { output[written] = 32; written += 1 }
        word := morse_word(int(morse_letter_index(input[index])))
        code_length := int((word / 256) % 8)
        mask := word % 32
        for position := 0; position < code_length; position += 1 {
            shift := code_length - position - 1
            if ((u64(mask) >> u64(shift)) & 1) != 0 do output[written] = 46
            else do output[written] = 45
            written += 1
        }
    }
    return i64(written)
}
