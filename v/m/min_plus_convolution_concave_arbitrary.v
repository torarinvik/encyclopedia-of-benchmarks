module min_plus_convolution_concave_arbitrary

const max_input = 67
const max_output = 504

struct MpcaContext {
	concave [32]i64
	arbitrary [32]i64
	y_min [63]int
	y_max [63]int
	x_min [32]int
	x_max [32]int
	result [63]i64
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

fn block_rows(mut c MpcaContext, x1 int, x2 int, y1 int, y2 int,
		row1 int, row2 int, q1 int, q2 int) {
	if row1 > row2 { return }
	mid := row1 + (row2-row1)/2
	x := x1+mid
	mut best := i64(9223372036854775807)
	mut best_q := q1
	for q in q1 .. q2+1 {
		y := y2-q
		value := c.arbitrary[y]+c.concave[x-y]
		if value < best { best=value; best_q=q }
	}
	if best < c.result[x] { c.result[x]=best }
	if row1 < mid { block_rows(mut c,x1,x2,y1,y2,row1,mid-1,q1,best_q) }
	if mid < row2 { block_rows(mut c,x1,x2,y1,y2,mid+1,row2,best_q,q2) }
}

fn scan_rectangle(mut c MpcaContext, x1 int, x2 int, y1 int, y2 int) {
	for x in x1 .. x2+1 {
		low := max(c.y_min[x],y1)
		high_y := min(c.y_max[x],y2)
		if low <= high_y {
			for y in low .. high_y+1 {
				value := c.arbitrary[y]+c.concave[x-y]
				if value < c.result[x] { c.result[x]=value }
			}
		}
	}
}

fn partition(mut c MpcaContext, x1 int, x2 int, y1 int, y2 int) {
	if x1 > x2 || y1 > y2 { return }
	if c.y_max[x1] >= y2 && y1 >= c.y_min[x2] {
		block_rows(mut c,x1,x2,y1,y2,0,x2-x1,0,y2-y1)
		return
	}
	if (x2-x1)*(y2-y1) < 1000 { scan_rectangle(mut c,x1,x2,y1,y2); return }
	if x2-x1 > y2-y1 {
		mid := (x1+x2)/2
		left_y2 := min(c.y_max[mid],y2)
		if y1 <= left_y2 { partition(mut c,x1,mid,y1,left_y2) }
		right_y1 := max(c.y_min[mid],y1)
		if right_y1 <= y2 { partition(mut c,mid+1,x2,right_y1,y2) }
	} else {
		mid := (y1+y2)/2
		left_x2 := min(c.x_max[mid],x2)
		if x1 <= left_x2 { partition(mut c,x1,left_x2,y1,mid) }
		right_x1 := max(c.x_min[mid],x1)
		if right_x1 <= x2 { partition(mut c,right_x1,x2,mid+1,y2) }
	}
}

@[export: 'min_plus_convolution_concave_arbitrary']
pub fn min_plus_convolution_concave_arbitrary(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		n0 := input[0]; m0 := input[1]
		if n0 < 1 || n0 > 32 || m0 < 1 || m0 > 32 { return -1 }
		n := int(n0); m := int(m0)
		if length != usize(2+n+m) { return -1 }
		mut c := MpcaContext{}
		for i in 0 .. n+m {
			value := input[2+i]
			if value < 0 || value > 1_000_000_000 { return -1 }
			if i < n { c.concave[i]=value } else { c.arbitrary[i-n]=value }
		}
		for i in 0 .. n { if i+2<n && c.concave[i+1]-c.concave[i] < c.concave[i+2]-c.concave[i+1] { return -1 } }
		h := n+m-1; bytes := 8*h
		if bytes > max_output { return -1 }
		if output == nil || capacity < usize(bytes) { return -2 }
		for x in 0 .. h {
			c.y_min[x] = if x >= n { x-n+1 } else { 0 }
			c.y_max[x] = min(m-1,x)
			c.result[x] = i64(9223372036854775807)
		}
		for y in 0 .. m { c.x_min[y]=y; c.x_max[y]=n-1+y }
		partition(mut c,0,h-1,0,m-1)
		for i in 0 .. h { store_i64_le(mut output,8*i,c.result[i]) }
		return i64(bytes)
	}
}
