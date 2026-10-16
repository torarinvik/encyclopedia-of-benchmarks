module dice_coefficient

import math

const invalid_result = -1.0e300
const max_string_length = 128
const alphabet_size = 95

@[export: 'dice_coefficient']
pub fn dice_coefficient(values &i64, length usize) f64 {
    if unsafe { values == nil } || length < 2 { return invalid_result }
    unsafe {
        len_a_raw := values[0]
        len_b_raw := values[1]
        if len_a_raw < 0 || len_a_raw > max_string_length || len_b_raw < 0 || len_b_raw > max_string_length { return invalid_result }
        len_a := int(len_a_raw)
        len_b := int(len_b_raw)
        if length != usize(2 + len_a + len_b) { return invalid_result }
        for i in 0 .. len_a+len_b {
            if values[2+i] < 32 || values[2+i] > 126 { return invalid_result }
        }
        mut equal := len_a == len_b
        mut i := 0
        for equal && i < len_a {
            if values[2+i] != values[2+len_a+i] { equal = false }
            i++
        }
        if equal { return 1.0 }
        if len_a < 2 || len_b < 2 { return 0.0 }
        mut present := [9025]bool{}
        for i in 0 .. len_a-1 {
            first := int(values[2+i] - 32)
            second := int(values[2+i+1] - 32)
            present[first*alphabet_size+second] = true
        }
        mut common := 0
        for j in 0 .. len_b-1 {
            first := int(values[2+len_a+j] - 32)
            second := int(values[2+len_a+j+1] - 32)
            if present[first*alphabet_size+second] { common++ }
        }
        denominator := f64(len_a + len_b - 2)
        score := (2.0 * f64(common)) / denominator
        return math.floor(score * 100.0) / 100.0
    }
}
