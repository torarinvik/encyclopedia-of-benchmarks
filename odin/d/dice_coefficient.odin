package dice_coefficient

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
MAX_STRING_LENGTH :: 128
ALPHABET_SIZE :: 95

@(export)
dice_coefficient :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 2 do return INVALID_RESULT
    len_a_raw := values[0]
    len_b_raw := values[1]
    if len_a_raw < 0 || len_a_raw > MAX_STRING_LENGTH || len_b_raw < 0 || len_b_raw > MAX_STRING_LENGTH do return INVALID_RESULT
    len_a := usize(len_a_raw)
    len_b := usize(len_b_raw)
    if length != c.size_t(2 + len_a + len_b) do return INVALID_RESULT
    for i: usize=0; i<len_a+len_b; i+=1 {
        if values[2+i] < 32 || values[2+i] > 126 do return INVALID_RESULT
    }
    equal := len_a == len_b
    for i: usize=0; equal && i<len_a; i+=1 {
        if values[2+i] != values[2+len_a+i] do equal = false
    }
    if equal do return 1.0
    if len_a < 2 || len_b < 2 do return 0.0
    present: [9025]bool
    for i: usize=0; i+1<len_a; i+=1 {
        first := usize(values[2+i]-32)
        second := usize(values[2+i+1]-32)
        present[first*ALPHABET_SIZE+second] = true
    }
    common: usize=0
    for i: usize=0; i+1<len_b; i+=1 {
        first := usize(values[2+len_a+i]-32)
        second := usize(values[2+len_a+i+1]-32)
        if present[first*ALPHABET_SIZE+second] do common += 1
    }
    denominator := f64(len_a+len_b-2)
    score := (2.0*f64(common))/denominator
    return math.floor_f64(score*100.0)/100.0
}
