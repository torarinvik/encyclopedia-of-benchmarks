// Uncompiled bounded GF(2) quadratic normal-form draft.
package quadratic_form_gf2_normal_form
import "core:c"

Vec :: [2]u64
Rows :: [100]Vec
qf_xor :: proc(a, b: Vec) -> Vec { return Vec{a[0] ~ b[0], a[1] ~ b[1]} }
qf_bit :: proc(v: Vec, i: int) -> bool { return (v[i/64] & (u64(1) << u64(i%64))) != 0 }
qf_set :: proc(v: ^Vec, i: int) { v[i/64] |= u64(1) << u64(i%64) }
qf_parity :: proc(value: u64) -> int {
    x := value
    x ~= x >> 32; x ~= x >> 16; x ~= x >> 8
    x ~= x >> 4; x ~= x >> 2; x ~= x >> 1
    return int(x & 1)
}
qf_apply :: proc(rows: ^Rows, n: int, a, b: Vec) -> int {
    result := 0
    for i := 0; i < n; i += 1 {
        if qf_bit(a, i) { result = result ~ qf_parity((rows[i][0] & b[0]) ~ (rows[i][1] & b[1])) }
    }
    return result
}

@(export)
quadratic_form_gf2_normal_form :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length == 0 || length > 202 || input[0] < 1 || input[0] > 100 do return -1
    n := int(input[0]); words := (n + 62) / 63
    if length != c.size_t(1 + n*words) do return -1
    upper, bilinear: Rows
    for i := 0; i < n; i += 1 {
        for chunk := 0; chunk < words; chunk += 1 {
            raw := input[1+i*words+chunk]
            if raw < 0 do return -1
            for b := 0; b < 63; b += 1 {
                if ((u64(raw) >> u64(b)) & 1) == 0 do continue
                j := 63*chunk+b
                if j >= n || j < i do return -1
                qf_set(&upper[i], j)
                if i != j { qf_set(&bilinear[i], j); qf_set(&bilinear[j], i) }
            }
        }
    }
    row_bytes := (n+7)/8; needed := 3+n*row_bytes
    if output == nil || capacity < c.size_t(needed) do return -2
    remaining, hyper, anis, columns: Rows
    for i := 0; i < n; i += 1 { qf_set(&remaining[i], i) }
    count, hc, ac := n, 0, 0
    for {
        left, right := count, count
        for i := 0; i < count && left == count; i += 1 {
            for j := i+1; j < count; j += 1 {
                if qf_apply(&bilinear, n, remaining[i], remaining[j]) != 0 {
                    left = i; right = j; break
                }
            }
        }
        if left == count do break
        u, v := remaining[left], remaining[right]
        rest: Rows
        next := 0
        for i := 0; i < count; i += 1 {
            if i == left || i == right do continue
            w := remaining[i]
            if qf_apply(&bilinear, n, remaining[i], v) != 0 { w = qf_xor(w, u) }
            if qf_apply(&bilinear, n, remaining[i], u) != 0 { w = qf_xor(w, v) }
            rest[next] = w; next += 1
        }
        remaining = rest; count = next
        qu, qv := qf_apply(&upper, n, u, u), qf_apply(&upper, n, v, v)
        if qu != 0 && qv != 0 {
            anis[ac] = u; anis[ac+1] = v; ac += 2
        } else {
            if qu != 0 { u = qf_xor(u, v) } else if qv != 0 { v = qf_xor(v, u) }
            hyper[hc] = u; hyper[hc+1] = v; hc += 2
        }
    }
    for ac >= 4 {
        a, b, cc, d := anis[ac-2], anis[ac-1], anis[ac-4], anis[ac-3]
        ac -= 4
        f := qf_xor(d, qf_xor(a, b))
        hyper[hc] = qf_xor(a, cc); hyper[hc+1] = qf_xor(b, cc)
        hyper[hc+2] = f; hyper[hc+3] = qf_xor(f, cc); hc += 4
    }
    linear: Vec
    has_linear := false
    for i := 0; i < count; i += 1 {
        if qf_apply(&upper, n, remaining[i], remaining[i]) == 0 do continue
        linear = remaining[i]; has_linear = true
        for j := i+1; j < count; j += 1 { remaining[j-1] = remaining[j] }
        count -= 1; break
    }
    if has_linear {
        for i := 0; i < count; i += 1 {
            if qf_apply(&upper, n, remaining[i], remaining[i]) != 0 { remaining[i] = qf_xor(remaining[i], linear) }
        }
        if ac != 0 {
            hyper[hc] = qf_xor(anis[0], linear); hyper[hc+1] = qf_xor(anis[1], linear)
            hc += 2; ac = 0
        }
    }
    used := 0
    for i := 0; i < hc; i += 1 { columns[used] = hyper[i]; used += 1 }
    for i := 0; i < ac; i += 1 { columns[used] = anis[i]; used += 1 }
    if has_linear { columns[used] = linear; used += 1 }
    for i := 0; i < count; i += 1 { columns[used] = remaining[i]; used += 1 }
    if used != n || hc%2 != 0 || (ac != 0 && ac != 2) do return -4
    matrix, inverse: Rows
    for i := 0; i < n; i += 1 {
        qf_set(&inverse[i], i)
        for j := 0; j < n; j += 1 { if qf_bit(columns[j], i) { qf_set(&matrix[i], j) } }
    }
    for col := 0; col < n; col += 1 {
        pivot := col
        for pivot < n && !qf_bit(matrix[pivot], col) { pivot += 1 }
        if pivot == n do return -4
        matrix[col], matrix[pivot] = matrix[pivot], matrix[col]
        inverse[col], inverse[pivot] = inverse[pivot], inverse[col]
        for row := 0; row < n; row += 1 {
            if row != col && qf_bit(matrix[row], col) {
                matrix[row] = qf_xor(matrix[row], matrix[col])
                inverse[row] = qf_xor(inverse[row], inverse[col])
            }
        }
    }
    staged: [1303]u8
    staged[0] = u8(hc/2); staged[1] = u8(ac/2)
    if has_linear { staged[2] = 1 }
    for i := 0; i < n; i += 1 {
        for j := 0; j < n; j += 1 {
            if qf_bit(inverse[i], j) { staged[3+i*row_bytes+j/8] |= u8(1 << u64(j%8)) }
        }
    }
    for i := 0; i < needed; i += 1 { output[i] = staged[i] }
    return i64(needed)
}
