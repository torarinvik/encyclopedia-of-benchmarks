// Uncompiled and unexecuted Odin half-GCD resultant draft.
package polynomial_resultant_half_gcd
import "core:c"

RESULTANT_PRIME :: i64(998244353)

resultant_power :: proc(value, exponent_value: i64) -> i64 {
    base, exponent, result := value, exponent_value, i64(1)
    for exponent > 0 {
        if exponent & 1 != 0 { result = result * base % RESULTANT_PRIME }
        base = base * base % RESULTANT_PRIME
        exponent >>= 1
    }
    return result
}

resultant_transform :: proc(values: []i64, inverse: bool) {
    n := len(values)
    reversed := 0
    for i := 1; i < n; i += 1 {
        bit := n >> 1
        for reversed & bit != 0 { reversed ~= bit; bit >>= 1 }
        reversed ~= bit
        if i < reversed { values[i], values[reversed] = values[reversed], values[i] }
    }
    for width := 2; width <= n; width *= 2 {
        step := resultant_power(3, (RESULTANT_PRIME - 1) / i64(width))
        if inverse { step = resultant_power(step, RESULTANT_PRIME - 2) }
        for start := 0; start < n; start += width {
            factor := i64(1)
            for k := 0; k < width / 2; k += 1 {
                x := values[start + k]
                y := values[start + k + width / 2] * factor % RESULTANT_PRIME
                values[start + k] = (x + y) % RESULTANT_PRIME
                values[start + k + width / 2] = (x - y + RESULTANT_PRIME) % RESULTANT_PRIME
                factor = factor * step % RESULTANT_PRIME
            }
        }
    }
    if inverse {
        scale := resultant_power(i64(n), RESULTANT_PRIME - 2)
        for i := 0; i < n; i += 1 { values[i] = values[i] * scale % RESULTANT_PRIME }
    }
}

// Returns an independently allocated canonical polynomial.
resultant_copy_trim :: proc(values: []i64) -> []i64 {
    count := len(values)
    for count > 0 && values[count - 1] == 0 { count -= 1 }
    output := make([]i64, count)
    for i := 0; i < count; i += 1 { output[i] = values[i] }
    return output
}

resultant_add :: proc(a, b: []i64) -> []i64 {
    count := len(a)
    if len(b) > count { count = len(b) }
    temporary := make([]i64, count)
    defer delete(temporary)
    for i := 0; i < len(a); i += 1 { temporary[i] = a[i] }
    for i := 0; i < len(b); i += 1 { temporary[i] = (temporary[i] + b[i]) % RESULTANT_PRIME }
    return resultant_copy_trim(temporary)
}

resultant_multiply :: proc(a, b: []i64) -> []i64 {
    if len(a) == 0 || len(b) == 0 { return make([]i64, 0) }
    count := len(a) + len(b) - 1
    output := make([]i64, count)
    defer delete(output)
    if len(a) <= 32 || len(b) <= 32 {
        for i := 0; i < len(a); i += 1 {
            for j := 0; j < len(b); j += 1 {
                output[i+j] = (output[i+j] + a[i] * b[j]) % RESULTANT_PRIME
            }
        }
    } else {
        size := 1
        for size < count { size *= 2 }
        left := make([]i64, size)
        right := make([]i64, size)
        defer delete(left)
        defer delete(right)
        for i := 0; i < len(a); i += 1 { left[i] = a[i] }
        for i := 0; i < len(b); i += 1 { right[i] = b[i] }
        resultant_transform(left, false)
        resultant_transform(right, false)
        for i := 0; i < size; i += 1 { left[i] = left[i] * right[i] % RESULTANT_PRIME }
        resultant_transform(left, true)
        for i := 0; i < count; i += 1 { output[i] = left[i] }
    }
    return resultant_copy_trim(output)
}

// Returns count coefficients, including trailing zeroes, for Newton doubling.
resultant_inverse :: proc(f: []i64, count: int) -> []i64 {
    inverse := make([]i64, 1)
    inverse[0] = resultant_power(f[0], RESULTANT_PRIME - 2)
    for len(inverse) < count {
        size := 2 * len(inverse)
        if size > count { size = count }
        prefix := len(f)
        if prefix > size { prefix = size }
        product := resultant_multiply(f[:prefix], inverse)
        correction := make([]i64, size)
        for i := 0; i < size; i += 1 {
            value := i64(0)
            if i < len(product) { value = product[i] }
            correction[i] = (RESULTANT_PRIME - value) % RESULTANT_PRIME
        }
        delete(product)
        correction[0] = (correction[0] + 2) % RESULTANT_PRIME
        updated := resultant_multiply(inverse, correction)
        delete(inverse)
        delete(correction)
        inverse = make([]i64, size)
        for i := 0; i < len(updated) && i < size; i += 1 { inverse[i] = updated[i] }
        delete(updated)
    }
    return inverse
}

// Caller owns both canonical returned polynomials. Divisor must be nonzero.
resultant_divrem :: proc(a, b: []i64) -> ([]i64, []i64) {
    if len(a) < len(b) { return make([]i64, 0), resultant_copy_trim(a) }
    count := len(a) - len(b) + 1
    high := make([]i64, count)
    reversed := make([]i64, len(b))
    for i := 0; i < count; i += 1 { high[i] = a[len(a) - 1 - i] }
    for i := 0; i < len(b); i += 1 { reversed[i] = b[len(b) - 1 - i] }
    inverse := resultant_inverse(reversed, count)
    qrev := resultant_multiply(high, inverse)
    delete(high)
    delete(reversed)
    delete(inverse)
    qbuf := make([]i64, count)
    for i := 0; i < count; i += 1 {
        index := count - 1 - i
        if index < len(qrev) { qbuf[i] = qrev[index] }
    }
    delete(qrev)
    removed := resultant_multiply(qbuf, b)
    rbuf := make([]i64, len(b) - 1)
    for i := 0; i < len(rbuf); i += 1 {
        value := i64(0)
        if i < len(removed) { value = removed[i] }
        rbuf[i] = (a[i] - value + RESULTANT_PRIME) % RESULTANT_PRIME
    }
    delete(removed)
    q := resultant_copy_trim(qbuf)
    r := resultant_copy_trim(rbuf)
    delete(qbuf)
    delete(rbuf)
    return q, r
}

Resultant_Matrix :: struct { a, b, c, d: []i64 }
Resultant_Head :: struct { degree: int, leading: i64 }

resultant_matrix_free :: proc(m: Resultant_Matrix) {
    delete(m.a); delete(m.b); delete(m.c); delete(m.d)
}

resultant_identity :: proc() -> Resultant_Matrix {
    m := Resultant_Matrix{}
    m.a = make([]i64, 1); m.a[0] = 1
    m.d = make([]i64, 1); m.d[0] = 1
    return m
}

resultant_step :: proc(q: []i64) -> Resultant_Matrix {
    m := Resultant_Matrix{}
    m.b = make([]i64, 1); m.b[0] = 1
    m.c = make([]i64, 1); m.c[0] = 1
    m.d = make([]i64, len(q))
    for i := 0; i < len(q); i += 1 { m.d[i] = (RESULTANT_PRIME - q[i]) % RESULTANT_PRIME }
    return m
}

resultant_dot :: proc(a, b, c, d: []i64) -> []i64 {
    first := resultant_multiply(a, b)
    second := resultant_multiply(c, d)
    result := resultant_add(first, second)
    delete(first); delete(second)
    return result
}

resultant_compose :: proc(x, y: Resultant_Matrix) -> Resultant_Matrix {
    return Resultant_Matrix{
        a = resultant_dot(x.a, y.a, x.b, y.c),
        b = resultant_dot(x.a, y.b, x.b, y.d),
        c = resultant_dot(x.c, y.a, x.d, y.c),
        d = resultant_dot(x.c, y.b, x.d, y.d),
    }
}

resultant_apply :: proc(m: Resultant_Matrix, a, b: []i64) -> ([]i64, []i64) {
    return resultant_dot(m.a, a, m.b, b), resultant_dot(m.c, a, m.d, b)
}

// Input slices are borrowed. Returned matrix owns its four entries. Heads
// has capacity at least the original first degree plus one.
resultant_half :: proc(a, b: []i64, heads: []Resultant_Head, count: ^int) -> Resultant_Matrix {
    if len(b) == 0 { return resultant_identity() }
    degree := len(a) - 1
    threshold := (degree + 1) / 2
    if len(b) <= threshold { return resultant_identity() }
    if degree <= 64 {
        x := resultant_copy_trim(a)
        y := resultant_copy_trim(b)
        matrix := resultant_identity()
        for len(y) > threshold && len(y) > 0 {
            q, r := resultant_divrem(x, y)
            heads[count^] = Resultant_Head{len(q)-1, q[len(q)-1]}
            count^ += 1
            step := resultant_step(q)
            next := resultant_compose(step, matrix)
            resultant_matrix_free(step)
            resultant_matrix_free(matrix)
            delete(q); delete(x)
            matrix = next
            x = y
            y = r
        }
        delete(x); delete(y)
        return matrix
    }
    first := resultant_half(a[threshold:], b[threshold:], heads, count)
    c, d := resultant_apply(first, a, b)
    if len(d) == 0 || len(d) <= threshold {
        delete(c); delete(d)
        return first
    }
    q, r := resultant_divrem(c, d)
    delete(c)
    heads[count^] = Resultant_Head{len(q)-1, q[len(q)-1]}
    count^ += 1
    step := resultant_step(q)
    prefix := resultant_compose(step, first)
    resultant_matrix_free(step); resultant_matrix_free(first)
    delete(q)
    if len(r) == 0 {
        delete(d); delete(r)
        return prefix
    }
    shift := 2 * threshold - (len(d) - 1)
    if shift >= len(r) {
        delete(d); delete(r)
        return prefix
    }
    last := resultant_half(d[shift:], r[shift:], heads, count)
    result := resultant_compose(last, prefix)
    resultant_matrix_free(last); resultant_matrix_free(prefix)
    delete(d); delete(r)
    return result
}

resultant_finish :: proc(a, b: []i64, value: i64) -> i64 {
    delete(a); delete(b)
    return value
}

resultant_value :: proc(first, second: []i64) -> i64 {
    a := resultant_copy_trim(first)
    b := resultant_copy_trim(second)
    answer := i64(1)
    if len(a) < len(b) {
        if (len(a)-1) & 1 != 0 && (len(b)-1) & 1 != 0 { answer = RESULTANT_PRIME - answer }
        a, b = b, a
    }
    heads := make([]Resultant_Head, len(a) + 1)
    defer delete(heads)
    for {
        if len(b) == 1 {
            value := answer * resultant_power(b[0], i64(len(a)-1)) % RESULTANT_PRIME
            return resultant_finish(a, b, value)
        }
        count := 0
        c, d: []i64
        if len(a) != len(b) {
            matrix := resultant_half(a, b, heads, &count)
            if count > 0 { c, d = resultant_apply(matrix, a, b) }
            resultant_matrix_free(matrix)
        }
        if count == 0 {
            q, r := resultant_divrem(a, b)
            delete(q)
            if len(r) == 0 { delete(r); return resultant_finish(a, b, 0) }
            da, db, dr := len(a)-1, len(b)-1, len(r)-1
            if da & 1 != 0 && db & 1 != 0 { answer = RESULTANT_PRIME - answer }
            answer = answer * resultant_power(b[len(b)-1], i64(da-dr)) % RESULTANT_PRIME
            delete(a)
            a = b
            b = r
        } else {
            if len(d) == 0 { delete(c); delete(d); return resultant_finish(a, b, 0) }
            da, db, lead := len(a)-1, len(b)-1, b[len(b)-1]
            for i := 0; i < count; i += 1 {
                last := i+1 == count
                dr := len(d)-1
                if !last { dr = db-heads[i+1].degree }
                if da & 1 != 0 && db & 1 != 0 { answer = RESULTANT_PRIME - answer }
                answer = answer * resultant_power(lead, i64(da-dr)) % RESULTANT_PRIME
                if !last { lead = lead * resultant_power(heads[i+1].leading, RESULTANT_PRIME-2) % RESULTANT_PRIME }
                da = db; db = dr
            }
            delete(a); delete(b)
            a = c; b = d
        }
    }
    return resultant_finish(a, b, answer)
}

@(export)
polynomial_resultant_half_gcd :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 100002 { return -1 }
    m, n := input[0], input[1]
    if m < 0 || m > 50000 || n < 0 || n > 50000 || m+n > 99998 { return -1 }
    first_count, second_count := int(m)+1, int(n)+1
    if length != c.size_t(first_count+second_count+2) { return -1 }
    a := make([]i64, first_count)
    b := make([]i64, second_count)
    defer delete(a); defer delete(b)
    for i := 0; i < first_count; i += 1 {
        a[i] = input[2+i]
        if a[i] < 0 || a[i] >= RESULTANT_PRIME { return -1 }
    }
    for i := 0; i < second_count; i += 1 {
        b[i] = input[2+first_count+i]
        if b[i] < 0 || b[i] >= RESULTANT_PRIME { return -1 }
    }
    if a[len(a)-1] == 0 || b[len(b)-1] == 0 { return -1 }
    return resultant_value(a, b)
}
