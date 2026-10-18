import math

const max_classes = 4
const max_samples = 16
const max_input = 22
const min_margin = 1e-8

fn lda_exact_integer(value f64, minimum f64, maximum f64) bool {
    if math.is_nan(value) || math.is_inf(value) || value < minimum || value > maximum { return false }
    return f64(int(value)) == value
}

@[export: 'linear_discriminant_analysis']
pub fn linear_discriminant_analysis(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
    unsafe {
        if input == nil || input_length == 0 || input_length > max_input { return -1 }
        if !lda_exact_integer(input[0], 2, 4) { return -1 }
        class_count := int(input[0])
        if input_length < usize(1 + class_count) { return -1 }
        mut counts := [max_classes]int{}
        mut total_count := 0
        for k in 0 .. class_count {
            if !lda_exact_integer(input[1 + k], 2, 6) { return -1 }
            counts[k] = int(input[1 + k])
            total_count += counts[k]
        }
        if total_count > max_samples || input_length != usize(1 + class_count + total_count) { return -1 }

        mut groups := [max_classes * 6]f64{}
        mut means := [max_classes]f64{}
        mut offset := 1 + class_count
        for k in 0 .. class_count {
            mut sum := 0.0
            for j in 0 .. counts[k] {
                x := input[offset]
                offset++
                if !lda_exact_integer(x, -32, 32) { return -1 }
                groups[k * 6 + j] = x
                sum += x
            }
            means[k] = sum / f64(counts[k])
            if !lda_exact_integer(means[k], -32, 32) { return -1 }
        }
        mut squared_sum := 0.0
        for k in 0 .. class_count {
            for j in 0 .. counts[k] {
                delta := groups[k * 6 + j] - means[k]
                squared_sum += delta * delta
            }
        }
        variance := (1.0 / f64(total_count - class_count)) * squared_sum
        if math.is_nan(variance) || math.is_inf(variance) || variance <= 0 { return -1 }
        mut priors := [max_classes]f64{}
        for k in 0 .. class_count { priors[k] = f64(counts[k]) / f64(total_count) }

        mut staged := [max_samples]f64{}
        mut n := 0
        for group in 0 .. class_count {
            for j in 0 .. counts[group] {
                x := groups[group * 6 + j]
                mut best := -1e300
                mut second := -1e300
                mut winner := 0
                for k in 0 .. class_count {
                    score := x * (means[k] / variance) - (means[k] * means[k] / (2.0 * variance)) + math.log(priors[k])
                    if score > best { second = best; best = score; winner = k }
                    else if score > second { second = score }
                }
                if math.is_nan(best) || math.is_inf(best) || best - second < min_margin { return -1 }
                staged[n] = f64(winner)
                n++
            }
        }
        if output == nil || capacity < usize(n) { return -2 }
        for i in 0 .. n { output[i] = staged[i] }
        return i64(n)
    }
}
