module spectral_norm

import math

const max_dimension = 64
const invalid_result = -1.0e300

fn matrix_entry(i int, j int) f64 {
    triangular := (i + j) * (i + j + 1) / 2
    return 1.0 / f64(triangular + i + 1)
}

fn multiply_a(n int, input []f64, mut output []f64) {
    for i in 0 .. n {
        mut total := 0.0
        for j in 0 .. n { total += matrix_entry(i, j) * input[j] }
        output[i] = total
    }
}

fn multiply_at(n int, input []f64, mut output []f64) {
    for i in 0 .. n {
        mut total := 0.0
        for j in 0 .. n { total += matrix_entry(j, i) * input[j] }
        output[i] = total
    }
}

fn multiply_ata(n int, input []f64, mut output []f64, mut temporary []f64) {
    multiply_a(n, input, mut temporary)
    multiply_at(n, temporary, mut output)
}

@[export: 'spectral_norm']
pub fn spectral_norm(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 1 { return invalid_result }
    unsafe {
        if values[0] < 1 || values[0] > max_dimension { return invalid_result }
        n := int(values[0])
        mut u := []f64{len: max_dimension, init: 0.0}
        mut v := []f64{len: max_dimension, init: 0.0}
        mut temporary := []f64{len: max_dimension, init: 0.0}
        for i in 0 .. n { u[i] = 1.0 }
        for _ in 0 .. 10 {
            multiply_ata(n, u, mut v, mut temporary)
            multiply_ata(n, v, mut u, mut temporary)
        }
        mut v_b_v := 0.0
        mut v_v := 0.0
        for i in 0 .. n {
            v_b_v += u[i] * v[i]
            v_v += v[i] * v[i]
        }
        return math.sqrt(v_b_v / v_v)
    }
}
