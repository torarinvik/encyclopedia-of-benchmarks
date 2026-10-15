package hill_cipher_mod97_cpp

import "core:c"

ALPHABET: [97]i64 = {65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32}
ENCRYPT_KEY :: [4]i64{2, 5, 1, 6}
DECRYPT_KEY :: [4]i64{84, 27, 83, 28}

alphabet_index :: proc(value: i64) -> int {
    for index := 0; index < 97; index += 1 { if ALPHABET[index] == value do return index }
    return -1
}

@(export)
hill_cipher_mod97_cpp :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 3 || length > 258 do return -1
    operation, raw_length := values[0], values[1]
    if (operation != 0 && operation != 1) || raw_length < 1 || raw_length > 256 || length != c.size_t(raw_length + 2) do return -1
    text_length := int(raw_length)
    indices: [256]u8
    for index := 0; index < text_length; index += 1 {
        mapped := alphabet_index(values[index + 2])
        if mapped < 0 do return -1
        indices[index] = u8(mapped)
    }
    output_length := text_length + text_length % 2
    if output == nil || output_capacity < c.size_t(output_length) do return -2
    key := if operation == 0 { ENCRYPT_KEY } else { DECRYPT_KEY }
    for offset := 0; offset < output_length; offset += 2 {
        first, second := i64(indices[offset]), i64(0)
        if offset + 1 < text_length do second = i64(indices[offset + 1])
        row0 := int((key[0] * first + key[1] * second) % 97)
        row1 := int((key[2] * first + key[3] * second) % 97)
        output[offset], output[offset + 1] = u8(ALPHABET[row0]), u8(ALPHABET[row1])
    }
    return i64(output_length)
}
