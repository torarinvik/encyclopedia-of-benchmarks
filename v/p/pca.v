import math

const max_samples = 8
const max_output = 12

@[export: 'pca']
pub fn pca(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
    unsafe {
        if input == nil || input_length < 9 || input_length > 19 { return -1 }
        if input[1] != 2.0 || input[2] != 1.0 || input[0] != input[0] || input[0] < 3.0 || input[0] > 8.0 { return -1 }
        n := int(input[0])
        if f64(n) != input[0] || input_length != usize(3 + 2 * n) { return -1 }
        mut x := [max_samples]f64{}
        mut y := [max_samples]f64{}
        mut z0 := [max_samples]f64{}
        mut z1 := [max_samples]f64{}
        mut mean0 := 0.0
        mut mean1 := 0.0
        for i in 0 .. n {
            x[i] = input[3 + 2 * i]
            y[i] = input[4 + 2 * i]
            if x[i] != x[i] || y[i] != y[i] || math.abs(x[i]) > 1000.0 || math.abs(y[i]) > 1000.0 { return -1 }
            mean0 += x[i]
            mean1 += y[i]
        }
        mean0 /= f64(n)
        mean1 /= f64(n)
        mut sum0 := 0.0
        mut sum1 := 0.0
        for i in 0 .. n {
            dx := x[i] - mean0
            dy := y[i] - mean1
            sum0 += dx * dx
            sum1 += dy * dy
        }
        denom := f64(n - 1)
        if sum0 <= 0.0 || sum1 <= 0.0 { return -1 }
        scale0 := math.sqrt(sum0 / denom)
        scale1 := math.sqrt(sum1 / denom)
        mut a := 0.0
        mut b := 0.0
        mut d := 0.0
        for i in 0 .. n {
            z0[i] = (x[i] - mean0) / scale0
            z1[i] = (y[i] - mean1) / scale1
            a += z0[i] * z0[i]
            b += z0[i] * z1[i]
            d += z1[i] * z1[i]
        }
        a /= denom
        b /= denom
        d /= denom
        root := math.sqrt((a - d) * (a - d) + 4.0 * b * b)
        lambda0 := 0.5 * (a + d + root)
        lambda1 := 0.5 * (a + d - root)
        if lambda0 - lambda1 <= 1e-8 { return -1 }
        mut vx := 0.0
        mut vy := 0.0
        if b == 0.0 {
            if a >= d { vx = 1.0 } else { vy = 1.0 }
        } else {
            vx = b
            vy = lambda0 - a
            norm := math.sqrt(vx * vx + vy * vy)
            if norm == 0.0 { return -1 }
            vx /= norm
            vy /= norm
        }
        abs_vx := if vx < 0.0 { -vx } else { vx }
        abs_vy := if vy < 0.0 { -vy } else { vy }
        if (abs_vx >= abs_vy && vx < 0.0) || (abs_vy > abs_vx && vy < 0.0) { vx = -vx; vy = -vy }
        mut staged := [max_output]f64{}
        for i in 0 .. n { staged[i] = z0[i] * vx + z1[i] * vy }
        staged[n] = vx
        staged[n + 1] = vy
        staged[n + 2] = lambda0
        staged[n + 3] = lambda1
        output_size := n + 4
        if output == nil || capacity < output_size { return -2 }
        for i in 0 .. output_size { output[i] = staged[i] }
        return i64(output_size)
    }
}
