package mono_alphabetic_cipher

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 183
FNV_OFFSET_BASIS :: u64(14_695_981_039_346_656_037)
FNV_PRIME :: u64(1_099_511_628_211)
MASK_63 :: u64(0x7fff_ffff_ffff_ffff)

@(export)
mono_alphabetic_cipher :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
    operation := input[0]
    raw_text_length := input[1]
    if (operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > 128 do return -1
    text_length := int(raw_text_length)
    if int(length) != 54 + text_length do return -1

    key_seen: [26]bool
    alphabet_seen: [26]bool
    key_inverse: [26]int
    alphabet_inverse: [26]int
    for i := 0; i < 26; i += 1 {
        key_value := input[2 + i]
        alphabet_value := input[28 + i]
        if key_value < 65 || key_value > 90 || alphabet_value < 65 || alphabet_value > 90 do return -1
        key_index := int(key_value - 65)
        alphabet_index := int(alphabet_value - 65)
        if key_seen[key_index] || alphabet_seen[alphabet_index] do return -1
        key_seen[key_index] = true
        alphabet_seen[alphabet_index] = true
        key_inverse[key_index] = i
        alphabet_inverse[alphabet_index] = i
    }
    output_length := 0
    for i := 0; i < text_length; i += 1 {
        value := input[54 + i]
        if !(value == 32 || (value >= 48 && value <= 57) ||
            (value >= 65 && value <= 90) || (value >= 97 && value <= 122)) do return -1
        if value < 48 || value > 57 do output_length += 1
    }

    hash := FNV_OFFSET_BASIS
    length_word := u64(output_length)
    for byte := 0; byte < 8; byte += 1 {
        hash = (hash ^ ((length_word >> u32(8 * byte)) & 255)) * FNV_PRIME
    }
    for i := 0; i < text_length; i += 1 {
        value := input[54 + i]
        if value >= 48 && value <= 57 do continue
        mapped := value
        if value != 32 {
            lower := value >= 97 && value <= 122
            letter := int(value - 65)
            if lower do letter = int(value - 97)
            position := if operation == 0 { alphabet_inverse[letter] } else { key_inverse[letter] }
            target := if operation == 0 { input[2 + position] } else { input[28 + position] }
            if lower do mapped = target + 32 else do mapped = target
        }
        hash = (hash ^ u64(mapped)) * FNV_PRIME
    }
    return i64(hash & MASK_63)
}
