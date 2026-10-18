package pca

import "core:c"
import "core:math"

MAX_SAMPLES :: 8
MAX_OUTPUT :: 12

@(export)
pca :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 9 || input_length > 19 do return -1
    if input[1] != 2.0 || input[2] != 1.0 || input[0] != input[0] || input[0] < 3.0 || input[0] > 8.0 do return -1
    n := int(input[0])
    if f64(n) != input[0] || input_length != c.size_t(3 + 2 * n) do return -1
    x: [MAX_SAMPLES]f64
    y: [MAX_SAMPLES]f64
    z0: [MAX_SAMPLES]f64
    z1: [MAX_SAMPLES]f64
    mean0, mean1: f64 = 0, 0
    for i in 0..<n {
        x[i] = input[3 + 2 * i]
        y[i] = input[4 + 2 * i]
        if x[i] != x[i] || y[i] != y[i] || x[i] < -1000 || x[i] > 1000 || y[i] < -1000 || y[i] > 1000 do return -1
        mean0 += x[i]; mean1 += y[i]
    }
    mean0 /= f64(n); mean1 /= f64(n)
    sum0, sum1: f64 = 0, 0
    for i in 0..<n { dx := x[i] - mean0; dy := y[i] - mean1; sum0 += dx*dx; sum1 += dy*dy }
    denom := f64(n - 1)
    if sum0 <= 0 || sum1 <= 0 do return -1
    scale0 := math.sqrt_f64(sum0 / denom)
    scale1 := math.sqrt_f64(sum1 / denom)
    a, b, d: f64 = 0, 0, 0
    for i in 0..<n { z0[i] = (x[i]-mean0)/scale0; z1[i] = (y[i]-mean1)/scale1; a += z0[i]*z0[i]; b += z0[i]*z1[i]; d += z1[i]*z1[i] }
    a /= denom; b /= denom; d /= denom
    root := math.sqrt_f64((a-d)*(a-d) + 4*b*b)
    lambda0 := 0.5 * (a + d + root)
    lambda1 := 0.5 * (a + d - root)
    if lambda0 - lambda1 <= 1e-8 do return -1
    vx, vy: f64
    if b == 0 {
        if a >= d { vx = 1 } else { vy = 1 }
    } else {
        vx = b; vy = lambda0 - a
        norm := math.sqrt_f64(vx*vx + vy*vy)
        if norm == 0 do return -1
        vx /= norm; vy /= norm
    }
    abs_vx := if vx < 0 { -vx } else { vx }
    abs_vy := if vy < 0 { -vy } else { vy }
    if (abs_vx >= abs_vy && vx < 0) || (abs_vy > abs_vx && vy < 0) { vx = -vx; vy = -vy }
    staged: [MAX_OUTPUT]f64
    for i in 0..<n { staged[i] = z0[i]*vx + z1[i]*vy }
    staged[n] = vx; staged[n+1] = vy; staged[n+2] = lambda0; staged[n+3] = lambda1
    output_size := n + 4
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i in 0..<output_size { output[i] = staged[i] }
    return i64(output_size)
}
