package mono_alphabetic_ciphers

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 157
FNV_OFFSET_BASIS :: u64(14_695_981_039_346_656_037)
FNV_PRIME :: u64(1_099_511_628_211)
MASK_63 :: u64(0x7fff_ffff_ffff_ffff)

@(export)
mono_alphabetic_ciphers :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
    operation := input[0]
    raw_text_length := input[1]
    if (operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > 128 do return -1
    text_length := int(raw_text_length)
    if int(length) != 28 + text_length do return -1

    seen: [26]bool
    inverse: [26]int
    for i := 0; i < 26; i += 1 {
        value := input[2 + i]
        if value < 65 || value > 90 do return -1
        letter := int(value - 65)
        if seen[letter] do return -1
        seen[letter] = true
        inverse[letter] = i
    }
    for i := 0; i < text_length; i += 1 {
        if input[28 + i] < 32 || input[28 + i] > 126 do return -1
    }

    hash := FNV_OFFSET_BASIS
    length_word := u64(text_length)
    for byte := 0; byte < 8; byte += 1 {
        hash = (hash ^ ((length_word >> u32(8 * byte)) & 255)) * FNV_PRIME
    }
    for i := 0; i < text_length; i += 1 {
        value := input[28 + i]
        mapped := value
        if (value >= 65 && value <= 90) || (value >= 97 && value <= 122) {
            lower := value >= 97 && value <= 122
            letter := int(value - 65)
            if lower do letter = int(value - 97)
            position := if operation == 0 { inverse[letter] } else { letter }
            target := if operation == 0 { i64(65 + position) } else { input[2 + position] }
            if lower do mapped = target + 32 else do mapped = target
        }
        hash = (hash ^ u64(mapped)) * FNV_PRIME
    }
    return i64(hash & MASK_63)
}
