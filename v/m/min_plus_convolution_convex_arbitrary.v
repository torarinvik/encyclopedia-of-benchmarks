module min_plus_convolution_convex_arbitrary

const max_input = 67
const max_output = 504

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'min_plus_convolution_convex_arbitrary']
pub fn min_plus_convolution_convex_arbitrary(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n0 := input[0]
		m0 := input[1]
		if n0 < 1 || n0 > 32 || m0 < 1 || m0 > 32 { return -1 }
		n := int(n0); m := int(m0)
		if length != usize(2+n+m) { return -1 }
		mut a := []i64{len: 32, init: 0}
		mut b := []i64{len: 32, init: 0}
		for i in 0 .. n+m {
			value := input[2+i]
			if value < 0 || value > 1_000_000_000 { return -1 }
			if i < n { a[i] = value } else { b[i-n] = value }
		}
		for i in 0 .. n { if i+2 < n && a[i+1]-a[i] > a[i+2]-a[i+1] { return -1 } }
		count := n+m-1
		bytes := 8*count
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		mut result := []i64{len: 63, init: 0}
		mut sl := []int{len: 128, init: 0}
		mut sr := []int{len: 128, init: 0}
		mut sol := []int{len: 128, init: 0}
		mut sor := []int{len: 128, init: 0}
		mut top := 1
		sl[0]=0; sr[0]=count-1; sol[0]=0; sor[0]=m-1
		for top > 0 {
			top--
			left,right := sl[top],sr[top]
			ol,or := sol[top],sor[top]
			if left > right { continue }
			mid := left+(right-left)/2
			low := max(ol,max(0,mid-(n-1)))
			high := min(or,min(m-1,mid))
			mut best := i64(9223372036854775807)
			mut best_j := low
			for j in low .. high+1 {
				candidate := a[mid-j]+b[j]
				if candidate < best { best=candidate; best_j=j }
			}
			result[mid]=best
			if mid < right { sl[top]=mid+1; sr[top]=right; sol[top]=best_j; sor[top]=or; top++ }
			if left < mid { sl[top]=left; sr[top]=mid-1; sol[top]=ol; sor[top]=best_j; top++ }
		}
		for i in 0 .. count { store_i64_le(mut output,8*i,result[i]) }
		return i64(bytes)
	}
}
