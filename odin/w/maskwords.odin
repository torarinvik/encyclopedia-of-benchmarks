package maskwords

import "core:c"

MAX_TEXT_BYTES :: 512
MAX_MASK_BYTES :: 16
MAX_PARSEABLE_INPUT_LENGTH :: 531
MAX_OUTPUT_BYTES :: 1447

is_word :: proc(value: u8) -> bool {
    return (value >= 65 && value <= 90) || (value >= 97 && value <= 122) ||
        (value >= 48 && value <= 57) || value == 95
}

is_normalized_target :: proc(text: [^]u8, start, finish: int) -> bool {
    length := finish - start
    if length == 5 {
        return (text[start] == 98 && text[start+1] == 105 && text[start+2] == 114 &&
                text[start+3] == 100 && text[start+4] == 115) ||
            (text[start] == 66 && text[start+1] == 73 && text[start+2] == 82 &&
                text[start+3] == 68 && text[start+4] == 83) ||
            (text[start] == 66 && text[start+1] == 105 && text[start+2] == 114 &&
                text[start+3] == 100 && text[start+4] == 115)
    }
    if length == 6 {
        return (text[start] == 109 && text[start+1] == 97 && text[start+2] == 114 &&
                text[start+3] == 107 && text[start+4] == 101 && text[start+5] == 116) ||
            (text[start] == 77 && text[start+1] == 65 && text[start+2] == 82 &&
                text[start+3] == 75 && text[start+4] == 69 && text[start+5] == 84) ||
            (text[start] == 77 && text[start+1] == 97 && text[start+2] == 114 &&
                text[start+3] == 107 && text[start+4] == 101 && text[start+5] == 116) ||
            (text[start] == 115 && text[start+1] == 116 && text[start+2] == 114 &&
                text[start+3] == 101 && text[start+4] == 101 && text[start+5] == 116) ||
            (text[start] == 83 && text[start+1] == 84 && text[start+2] == 82 &&
                text[start+3] == 69 && text[start+4] == 69 && text[start+5] == 84) ||
            (text[start] == 83 && text[start+1] == 116 && text[start+2] == 114 &&
                text[start+3] == 101 && text[start+4] == 101 && text[start+5] == 116)
    }
    return false
}

match_length :: proc(text: [^]u8, start, finish, position: int) -> int {
    length := 0
    if position + 5 <= finish && text[position] == 98 && text[position+1] == 105 &&
        text[position+2] == 114 && text[position+3] == 100 && text[position+4] == 115 {
        length = 5
    } else if position + 6 <= finish && text[position] == 109 && text[position+1] == 97 &&
        text[position+2] == 114 && text[position+3] == 107 && text[position+4] == 101 &&
        text[position+5] == 116 {
        length = 6
    } else if position + 6 <= finish && text[position] == 115 && text[position+1] == 116 &&
        text[position+2] == 114 && text[position+3] == 101 && text[position+4] == 101 &&
        text[position+5] == 116 {
        length = 6
    }
    if length == 0 || (position > start && is_word(text[position-1])) ||
        (position + length < finish && is_word(text[position+length])) {
        return 0
    }
    return length
}

append_token :: proc(text: [^]u8, start, finish: int, mask: [^]u8,
                     mask_length: int, output: [^]u8, written_value: int) -> int {
    written := written_value
    if is_normalized_target(text, start, finish) {
        for i := 0; i < mask_length; i += 1 {
            output[written] = mask[i]
            written += 1
        }
        return written
    }
    position := start
    for position < finish {
        matched := match_length(text, start, finish, position)
        if matched != 0 {
            for i := 0; i < mask_length; i += 1 {
                output[written] = mask[i]
                written += 1
            }
            position += matched
        } else {
            if text[position] != 10 {
                output[written] = text[position]
                written += 1
            }
            position += 1
        }
    }
    return written
}

@(export)
maskwords :: proc "c" (values: [^]i64, length: c.size_t,
                       output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
    if values[0] < 0 || values[0] > MAX_TEXT_BYTES do return -1
    text_length := int(values[0])
    mask_length_index := 1 + text_length
    if mask_length_index >= int(length) || values[mask_length_index] < 0 ||
        values[mask_length_index] > MAX_MASK_BYTES do return -1
    mask_length := int(values[mask_length_index])
    if int(length) != mask_length_index + 1 + mask_length do return -1

    text_storage: [MAX_TEXT_BYTES]u8
    mask_storage: [MAX_MASK_BYTES]u8
    for i := 0; i < text_length; i += 1 {
        value := values[1+i]
        if value < 1 || value > 127 do return -1
        text_storage[i] = u8(value)
    }
    for i := 0; i < mask_length; i += 1 {
        value := values[mask_length_index+1+i]
        if value < 32 || value > 126 || value == 92 do return -1
        mask_storage[i] = u8(value)
    }

    scratch: [MAX_OUTPUT_BYTES]u8
    written := 0
    start := 0
    have_token := false
    for i := 0; i < text_length; i += 1 {
        if text_storage[i] == 32 {
            if have_token {
                scratch[written] = 32
                written += 1
            }
            written = append_token(&text_storage[0], start, i, &mask_storage[0],
                                   mask_length, &scratch[0], written)
            have_token = true
            start = i + 1
        }
    }
    if start < text_length {
        if have_token {
            scratch[written] = 32
            written += 1
        }
        written = append_token(&text_storage[0], start, text_length, &mask_storage[0],
                               mask_length, &scratch[0], written)
    }
    if written > MAX_OUTPUT_BYTES do return -1
    if capacity < c.size_t(written) || (written != 0 && output == nil) do return -2
    for i := 0; i < written; i += 1 { output[i] = scratch[i] }
    return i64(written)
}
