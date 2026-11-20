package knuth_big_integer_division

import "core:c"

BASE :: i64(1_000_000_000)
MAX_LIMBS :: 8
MAX_INPUT :: c.size_t(130)
MAX_OUTPUT :: 129
Limbs :: [MAX_LIMBS]i64

trim :: proc(x: ^Limbs, count_input: int) -> int {
    count := count_input
    for count > 0 && x[count - 1] == 0 { count -= 1 }
    return count
}

parse_limbs :: proc(input: [^]i64, start: int, length: int, x: ^Limbs) -> int {
    count := 0
    for at := 0; at < length; at += 1 {
        carry := input[start + at] - 48
        for i := 0; i < count; i += 1 {
            carry += x[i] * 10
            x[i] = carry % BASE
            carry /= BASE
        }
        if carry != 0 { x[count] = carry; count += 1 }
        if count == 0 { count = 1 }
    }
    return trim(x, count)
}

compare :: proc(a: ^Limbs, na: int, b: ^Limbs, nb: int) -> int {
    if na != nb { if na > nb { return 1 }; return -1 }
    for i := na - 1; i >= 0; i -= 1 {
        if a[i] != b[i] { if a[i] > b[i] { return 1 }; return -1 }
    }
    return 0
}

divide_limbs :: proc(a: ^Limbs, na: int, b: ^Limbs, nb: int, q: ^Limbs, r: ^Limbs) -> (int, int) {
    if na == 0 { return 0, 0 }
    if compare(a, na, b, nb) < 0 { r^ = a^; return 0, na }
    if nb == 1 {
        rem := i64(0)
        for i := na - 1; i >= 0; i -= 1 {
            current := rem * BASE + a[i]
            q[i] = current / b[0]
            rem = current % b[0]
        }
        if rem != 0 { r[0] = rem; return trim(q, na), 1 }
        return trim(q, na), 0
    }
    v: [MAX_LIMBS]i64
    u: [MAX_LIMBS + 1]i64
    n := nb
    scale := BASE / (b[n - 1] + 1)
    carry := i64(0)
    for i := 0; i < n; i += 1 { current := b[i] * scale + carry; v[i] = current % BASE; carry = current / BASE }
    carry = 0
    for i := 0; i < na; i += 1 { current := a[i] * scale + carry; u[i] = current % BASE; carry = current / BASE }
    u[na] = carry
    width := na - n + 1
    for step := width - 1; step >= 0; step -= 1 {
        j := step
        numerator := u[j + n] * BASE + u[j + n - 1]
        estimate := numerator / v[n - 1]
        rem_estimate := numerator % v[n - 1]
        if estimate >= BASE { estimate = BASE - 1; rem_estimate = numerator - estimate * v[n - 1] }
        for rem_estimate < BASE && estimate * v[n - 2] > rem_estimate * BASE + u[j + n - 2] {
            estimate -= 1
            rem_estimate += v[n - 1]
        }
        borrow := i64(0)
        for i := 0; i < n; i += 1 {
            product := estimate * v[i] + borrow
            low := product % BASE
            borrow = product / BASE
            difference := u[j + i] - low
            if difference < 0 { difference += BASE; borrow += 1 }
            u[j + i] = difference
        }
        top := u[j + n] - borrow
        if top < 0 {
            estimate -= 1
            carry = 0
            for i := 0; i < n; i += 1 {
                sum := u[j + i] + v[i] + carry
                if sum >= BASE { sum -= BASE; carry = 1 } else { carry = 0 }
                u[j + i] = sum
            }
            u[j + n] = top + carry
        } else { u[j + n] = top }
        q[j] = estimate
    }
    carry = 0
    for i := n - 1; i >= 0; i -= 1 { current := carry * BASE + u[i]; r[i] = current / scale; carry = current % scale }
    return trim(q, width), trim(r, n)
}

emit_decimal :: proc(x: ^Limbs, count_input: int, output: [^]u8, at_input: int) -> int {
    count := trim(x, count_input)
    at := at_input
    if count == 0 { output[at] = 48; return at + 1 }
    value := x[count - 1]
    power := i64(1)
    for value / power >= 10 { power *= 10 }
    for power > 0 { output[at] = u8(48 + value / power % 10); at += 1; power /= 10 }
    for count > 1 {
        count -= 1
        value = x[count - 1]
        power = BASE / 10
        for power > 0 { output[at] = u8(48 + value / power % 10); at += 1; power /= 10 }
    }
    return at
}

@(export)
knuth_big_integer_division :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT do return -1
    if input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64 do return -1
    na_text, nb_text := int(input[0]), int(input[1])
    if int(length) != 2 + na_text + nb_text do return -1
    for i := 0; i < na_text; i += 1 { if input[2 + i] < 48 || input[2 + i] > 57 do return -1 }
    for i := 0; i < nb_text; i += 1 { if input[2 + na_text + i] < 48 || input[2 + na_text + i] > 57 do return -1 }
    if (na_text > 1 && input[2] == 48) || (nb_text > 1 && input[2 + na_text] == 48) ||
       (nb_text == 1 && input[2 + na_text] == 48) do return -1
    a, b, q, r: Limbs
    na := parse_limbs(input, 2, na_text, &a)
    nb := parse_limbs(input, 2 + na_text, nb_text, &b)
    nq, nr := divide_limbs(&a, na, &b, nb, &q, &r)
    result: [MAX_OUTPUT]u8
    bytes := emit_decimal(&q, nq, &result[0], 0)
    result[bytes] = 58
    bytes += 1
    bytes = emit_decimal(&r, nr, &result[0], bytes)
    if output == nil || int(capacity) < bytes do return -2
    for i := 0; i < bytes; i += 1 { output[i] = result[i] }
    return i64(bytes)
}
