import math

fn exact_integer(value f64, low i64, high i64) bool {
	return value.is_finite() && value >= f64(low) && value <= f64(high) && f64(i64(value)) == value
}

fn evaluate(p int, n int, u f64, knots &f64, controls &f64) f64 {
	mut span := p
	if u == knots[n] { span = n-1 } else {
		for span < n-1 && u >= knots[span+1] { span++ }
	}
	mut local := [4]f64{}
	for j in 0..p+1 { local[j] = controls[span-p+j] }
	for level := 1; level <= p; level++ {
		for mut slot := p; slot >= level; slot-- {
			left := span-p+slot
			right := span+slot-level+1
			denominator := knots[right]-knots[left]
			alpha := if denominator == 0.0 { 0.0 } else { (u-knots[left])/denominator }
			local[slot] = (1.0-alpha)*local[slot-1]+alpha*local[slot]
		}
	}
	return local[p]
}

@[export: 'de_boor_bspline_curve_evaluation']
pub fn de_boor_bspline_curve_evaluation(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 24 { return -1 }
		if !exact_integer(input[0],1,3) { return -1 }
		p := int(input[0])
		if !exact_integer(input[1],i64(p+1),8) || !input[2].is_finite() { return -1 }
		n := int(input[1])
		knot_count := n+p+1
		if input_length != usize(3+knot_count+n) { return -1 }
		knots := input[3..3+knot_count]
		controls := input[3+knot_count..3+knot_count+n]
		mut run := 1
		for i in 0..knot_count {
			if !knots[i].is_finite() || knots[i] < -1000.0 || knots[i] > 1000.0 { return -1 }
			if i > 0 {
				if knots[i] < knots[i-1] { return -1 }
				run = if knots[i] == knots[i-1] { run+1 } else { 1 }
				if run > p+1 { return -1 }
			}
		}
		for i in 0..n { if !controls[i].is_finite() || controls[i] < -1000.0 || controls[i] > 1000.0 { return -1 } }
		if !(knots[p] < knots[n] && input[2] >= knots[p] && input[2] <= knots[n]) { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		result := evaluate(p,n,input[2],knots,controls)
		if !result.is_finite() { return -1 }
		output[0] = result
		return 1
	}
}
