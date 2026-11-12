package min_plus_convolution_convex_arbitrary
import "core:c"

MAX_INPUT :: 67
MAX_OUTPUT :: 504

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits&255); bits >>= 8 }
}

@(export)
min_plus_convolution_convex_arbitrary :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > 32 || m0 < 1 || m0 > 32 do return -1
	n, m := int(n0), int(m0)
	if length != c.size_t(2+n+m) do return -1
	a: [32]i64
	b: [32]i64
	for i := 0; i < n+m; i += 1 {
		value := input[2+i]
		if value < 0 || value > 1_000_000_000 do return -1
		if i < n { a[i] = value } else { b[i-n] = value }
	}
	for i := 0; i+2 < n; i += 1 { if a[i+1]-a[i] > a[i+2]-a[i+1] do return -1 }
	count := n+m-1
	bytes := 8*count
	if bytes > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	result: [63]i64
	stack_left, stack_right, stack_opt_left, stack_opt_right: [128]int
	top := 1
	stack_left[0] = 0; stack_right[0] = count-1; stack_opt_left[0] = 0; stack_opt_right[0] = m-1
	for top > 0 {
		top -= 1
		left, right := stack_left[top], stack_right[top]
		ol, or := stack_opt_left[top], stack_opt_right[top]
		if left > right do continue
		mid := left+(right-left)/2
		low := max(ol, max(0, mid-(n-1)))
		high := min(or, min(m-1, mid))
		best: i64 = 9223372036854775807
		best_j := low
		for j := low; j <= high; j += 1 {
			candidate := a[mid-j]+b[j]
			if candidate < best { best = candidate; best_j = j }
		}
		result[mid] = best
		if mid < right { stack_left[top]=mid+1; stack_right[top]=right; stack_opt_left[top]=best_j; stack_opt_right[top]=or; top+=1 }
		if left < mid { stack_left[top]=left; stack_right[top]=mid-1; stack_opt_left[top]=ol; stack_opt_right[top]=best_j; top+=1 }
	}
	for i := 0; i < count; i += 1 { store_i64_le(output,8*i,result[i]) }
	return i64(bytes)
}
