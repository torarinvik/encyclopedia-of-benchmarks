package min_plus_convolution_concave_arbitrary
import "core:c"

MAX_INPUT :: 67
MAX_OUTPUT :: 504

Context :: struct {
	concave, arbitrary: [32]i64,
	n, m, h: int,
	y_min, y_max: [63]int,
	x_min, x_max: [32]int,
	result: [63]i64,
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits&255); bits >>= 8 }
}

block_rows :: proc(c: ^Context, x1, x2, y1, y2, row1, row2, q1, q2: int) {
	if row1 > row2 do return
	mid := row1+(row2-row1)/2
	x := x1+mid
	best: i64 = 9223372036854775807
	best_q := q1
	for q := q1; q <= q2; q += 1 {
		y := y2-q
		value := c.arbitrary[y]+c.concave[x-y]
		if value < best { best=value; best_q=q }
	}
	if best < c.result[x] { c.result[x]=best }
	if row1 < mid do block_rows(c,x1,x2,y1,y2,row1,mid-1,q1,best_q)
	if mid < row2 do block_rows(c,x1,x2,y1,y2,mid+1,row2,best_q,q2)
}

scan_rectangle :: proc(c: ^Context, x1, x2, y1, y2: int) {
	for x := x1; x <= x2; x += 1 {
		low := max(c.y_min[x],y1); high_y := min(c.y_max[x],y2)
		if low > high_y do continue
		for y := low; y <= high_y; y += 1 {
			value := c.arbitrary[y]+c.concave[x-y]
			if value < c.result[x] { c.result[x]=value }
		}
	}
}

partition :: proc(c: ^Context, x1, x2, y1, y2: int) {
	if x1 > x2 || y1 > y2 do return
	if c.y_max[x1] >= y2 && y1 >= c.y_min[x2] {
		block_rows(c,x1,x2,y1,y2,0,x2-x1,0,y2-y1)
		return
	}
	if (x2-x1)*(y2-y1) < 1000 { scan_rectangle(c,x1,x2,y1,y2); return }
	if x2-x1 > y2-y1 {
		mid := (x1+x2)/2
		left_y2 := min(c.y_max[mid],y2)
		if y1 <= left_y2 { partition(c,x1,mid,y1,left_y2) }
		right_y1 := max(c.y_min[mid],y1)
		if right_y1 <= y2 { partition(c,mid+1,x2,right_y1,y2) }
	} else {
		mid := (y1+y2)/2
		left_x2 := min(c.x_max[mid],x2)
		if x1 <= left_x2 { partition(c,x1,left_x2,y1,mid) }
		right_x1 := max(c.x_min[mid],x1)
		if right_x1 <= x2 { partition(c,right_x1,x2,mid+1,y2) }
	}
}

@(export)
min_plus_convolution_concave_arbitrary :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n0,m0 := input[0],input[1]
	if n0 < 1 || n0 > 32 || m0 < 1 || m0 > 32 do return -1
	n,m := int(n0),int(m0)
	if length != c.size_t(2+n+m) do return -1
	ctx := Context{}
	ctx.n=m; ctx.m=n; ctx.h=n+m-1
	for i := 0; i < n+m; i += 1 {
		value := input[2+i]
		if value < 0 || value > 1_000_000_000 do return -1
		if i < n { ctx.concave[i]=value } else { ctx.arbitrary[i-n]=value }
	}
	for i := 0; i+2 < n; i += 1 { if ctx.concave[i+1]-ctx.concave[i] < ctx.concave[i+2]-ctx.concave[i+1] do return -1 }
	bytes := 8*ctx.h
	if bytes > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	for x := 0; x < ctx.h; x += 1 {
		ctx.y_min[x]=0
		if x >= n { ctx.y_min[x]=x-n+1 }
		ctx.y_max[x]=min(m-1,x)
		ctx.result[x]=9223372036854775807
	}
	for y := 0; y < m; y += 1 { ctx.x_min[y]=y; ctx.x_max[y]=n-1+y }
	partition(&ctx,0,ctx.h-1,0,m-1)
	for i := 0; i < ctx.h; i += 1 { store_i64_le(output,8*i,ctx.result[i]) }
	return i64(bytes)
}
