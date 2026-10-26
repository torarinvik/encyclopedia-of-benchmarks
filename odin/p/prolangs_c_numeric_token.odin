package prolangs_c_numeric_token

import "core:c"

put_i32 :: proc(out: [^]u8, at: int, value: i32) {
    bits := transmute(u32)value
    for b in 0..<4 { out[at+b] = u8((bits >> (b*8)) & 255) }
}

@(export)
prolangs_c_numeric_token :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 24 do return -1
    n := int(length)
    text: [24]u8
    for j in 0..<n { if input[j] < 32 || input[j] > 127 do return -1; text[j] = u8(input[j]) }
    i := 0; integer: u32 = 0; had_integer := false
    if text[i] >= 48 && text[i] <= 57 {
        had_integer = true
        for i < n && text[i] >= 48 && text[i] <= 57 {
            d := u32(text[i]-48); i += 1
            if integer > (2147483647-d)/10 do return -1
            integer = integer*10+d
        }
        if i == n {
            if capacity < 12 || output == nil do return -2
            put_i32(output,0,256); put_i32(output,4,i32(integer)); put_i32(output,8,0); return 12
        }
    }
    frac_digits: u32 = 0; frac_count := 0; leading_zeros := 0; has_dot := false
    if i < n && text[i] == 46 {
        has_dot = true; i += 1
        for i < n && text[i] == 48 { leading_zeros += 1; i += 1 }
        if leading_zeros > 6 do return -1
        for i < n && text[i] >= 48 && text[i] <= 57 {
            if frac_count == 6 do return -1
            frac_digits = frac_digits*10+u32(text[i]-48); frac_count += 1; i += 1
        }
        if leading_zeros + frac_count > 6 do return -1
    }
    value: f32 = 0
    if frac_count != 0 {
        value = f32(frac_digits)
        for value >= 1 { value /= 10 }
        for leading_zeros > 0 { value /= 10; leading_zeros -= 1 }
    }
    value += f32(integer)
    has_exp := false
    if i < n && (text[i] == 101 || text[i] == 69) {
        has_exp = true; i += 1; sign := 1
        if i < n && (text[i] == 43 || text[i] == 45) { if text[i] == 45 { sign = -1 }; i += 1 }
        if i == n || text[i] < 48 || text[i] > 57 do return -1
        exponent := 0
        for i < n && text[i] >= 48 && text[i] <= 57 { exponent=exponent*10+int(text[i]-48); i+=1; if exponent>6 do return -1 }
        exponent *= sign
        for exponent > 0 { value *= 10; exponent -= 1 }
        for exponent < 0 { value /= 10; exponent += 1 }
    }
    if i != n || (!has_dot && !has_exp) || (!had_integer && !has_dot) do return -1
    if capacity < 12 || output == nil do return -2
    put_i32(output,0,2001); put_i32(output,4,i32(integer)); put_i32(output,8,transmute(i32)value)
    return 12
}
