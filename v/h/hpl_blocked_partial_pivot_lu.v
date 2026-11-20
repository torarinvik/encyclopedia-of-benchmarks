import math

@[export: 'hpl_blocked_partial_pivot_lu']
pub fn hpl_blocked_partial_pivot_lu(input &f64, input_length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 1 || input_length > 66 { return -1 }
		nv := input[0]
		if !nv.is_finite() || nv != f64(int(nv)) || nv < 2 || nv > 8 { return -1 }
		n := int(nv)
		if input_length != usize(1+n*n) { return -1 }
		mut a := [64]f64{}
		for i in 0 .. n*n {
			x := input[i+1]
			if !x.is_finite() || x != f64(int(x)) || x < -16 || x > 16 { return -1 }
			a[i] = x
		}
		mut pivots := [8]int{}
		mut panel := 0
		for panel < n {
			mut panel_end := panel+2
			if panel_end > n { panel_end = n }
			for col := panel; col < panel_end; col++ {
				mut pivot_row := col
				mut pivot_magnitude := math.abs(a[col*n+col])
				for row := col+1; row < n; row++ {
					magnitude := math.abs(a[row*n+col])
					if magnitude > pivot_magnitude { pivot_magnitude = magnitude; pivot_row = row }
				}
				if !pivot_magnitude.is_finite() || pivot_magnitude == 0 { return -1 }
				pivots[col] = pivot_row
				if pivot_row != col {
					for j := 0; j < n; j++ {
						temp := a[col*n+j]; a[col*n+j] = a[pivot_row*n+j]; a[pivot_row*n+j] = temp
					}
				}
				diagonal := a[col*n+col]
				if !diagonal.is_finite() || diagonal == 0 { return -1 }
				for row := col+1; row < n; row++ {
					a[row*n+col] /= diagonal
					if !a[row*n+col].is_finite() { return -1 }
					multiplier := a[row*n+col]
					for j := col+1; j < panel_end; j++ {
						a[row*n+j] -= multiplier*a[col*n+j]
						if !a[row*n+j].is_finite() { return -1 }
					}
				}
			}
			for row := panel; row < panel_end; row++ {
				for col := panel_end; col < n; col++ {
					mut value := a[row*n+col]
					for inner := panel; inner < row; inner++ { value -= a[row*n+inner]*a[inner*n+col] }
					if !value.is_finite() { return -1 }
					a[row*n+col] = value
				}
			}
			for row := panel_end; row < n; row++ {
				for col := panel_end; col < n; col++ {
					mut update := 0.0
					for inner := panel; inner < panel_end; inner++ { update += a[row*n+inner]*a[inner*n+col] }
					a[row*n+col] -= update
					if !a[row*n+col].is_finite() { return -1 }
				}
			}
			panel = panel_end
		}
		mut staged := [72]f64{}
		for i in 0 .. n { staged[i] = f64(pivots[i]) }
		for i in 0 .. n*n {
			if !a[i].is_finite() { return -1 }
			staged[n+i] = a[i]
		}
		length := n+n*n
		if output == nil || capacity < usize(length) { return -2 }
		for i in 0 .. length { output[i] = staged[i] }
		return i64(length)
	}
}
