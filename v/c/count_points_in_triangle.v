module count_points_in_triangle

const max_n = 24
const max_m = 24
const max_q = 128
const input_max = 483
const bit_stride = max_m + 1

struct Point { x i64; y i64 }
struct Vector { x i64; y i64 }
struct Query { a i64; b i64; c i64 }

fn angle_half(v Vector) int {
	if v.y < 0 { return 0 }
	if v.y == 0 && v.x >= 0 { return 1 }
	return 2
}
fn angle_less(a Vector, b Vector) bool {
	ha, hb := angle_half(a), angle_half(b)
	if ha != hb { return ha < hb }
	return a.x*b.y-a.y*b.x > 0
}
fn direction_less(a Vector, b Vector) bool {
	if angle_less(a,b) { return true }
	if angle_less(b,a) { return false }
	ra, rb := a.x*a.x+a.y*a.y, b.x*b.x+b.y*b.y
	if ra != rb { return ra < rb }
	if a.x != b.x { return a.x < b.x }
	return a.y < b.y
}
fn lower_ray(dirs []Vector, ray Vector) int {
	mut low := 0
	mut high := dirs.len
	for low < high { mid := low+(high-low)/2; if angle_less(dirs[mid],ray) { low=mid+1 } else { high=mid } }
	return low
}
fn upper_ray(dirs []Vector, ray Vector) int {
	mut low := 0
	mut high := dirs.len
	for low < high { mid := low+(high-low)/2; if !angle_less(ray,dirs[mid]) { low=mid+1 } else { high=mid } }
	return low
}
fn fenwick_prefix(bit []i32, end_value int) int {
	mut end := end_value
	mut total := 0
	for end > 0 { total += bit[end]; end &= end-1 }
	return total
}
fn arc_count(dirs []Vector, bit []i32, start Vector, finish Vector) int {
	left := lower_ray(dirs,start)
	right := upper_ray(dirs,finish)
	if !angle_less(finish,start) { return fenwick_prefix(bit,right)-fenwick_prefix(bit,left) }
	return fenwick_prefix(bit,dirs.len)-fenwick_prefix(bit,left)+fenwick_prefix(bit,right)
}
fn halfplane_count(u int, v int, a []Point, dirs []Vector, counts []int, zeros []int, bit []i32) int {
	edge := Vector{x:a[v].x-a[u].x,y:a[v].y-a[u].y}
	dir_base := u*max_m
	bit_base := u*bit_stride
	return zeros[u]+arc_count(dirs[dir_base..dir_base+counts[u]],bit[bit_base..bit_base+counts[u]+1],Vector{x:-edge.x,y:-edge.y},edge)
}
fn store_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset+byte]=u8((bits>>(8*byte))&255) } }
}

@[export: 'count_points_in_triangle']
pub fn count_points_in_triangle(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input==nil || length<3 || length>input_max { return -1 }
		nr,mr,qr := input[0],input[1],input[2]
		if nr<1 || nr>max_n || mr<1 || mr>max_m || qr<1 || qr>max_q { return -1 }
		n,m,q := int(nr),int(mr),int(qr)
		if int(length)!=3+2*n+2*m+3*q { return -1 }
		mut a := [max_n]Point{}
		mut b := [max_m]Point{}
		mut queries := [max_q]Query{}
		mut cursor := 3
		for i in 0 .. n { a[i]=Point{x:input[cursor],y:input[cursor+1]};cursor+=2;if a[i].x < -1_000_000_000 || a[i].x>1_000_000_000 || a[i].y < -1_000_000_000 || a[i].y>1_000_000_000{return -1} }
		for i in 0 .. m { b[i]=Point{x:input[cursor],y:input[cursor+1]};cursor+=2;if b[i].x < -1_000_000_000 || b[i].x>1_000_000_000 || b[i].y < -1_000_000_000 || b[i].y>1_000_000_000{return -1} }
		for i in 0 .. q { ia,ib,ic:=input[cursor],input[cursor+1],input[cursor+2];cursor+=3;if ia<0||ia>=nr||ib<0||ib>=nr||ic<0||ic>=nr{return -1};queries[i]=Query{ia,ib,ic} }
		required:=8*q;if output==nil||capacity<usize(required){return -2}
		mut dirs:=[max_n*max_m]Vector{}
		mut counts:=[max_n]int{}
		mut zeros:=[max_n]int{}
		mut bit:=[max_n*bit_stride]i32{}
		for u in 0 .. n {
			for j in 0 .. m { v:=Vector{x:b[j].x-a[u].x,y:b[j].y-a[u].y};if v.x==0&&v.y==0{zeros[u]++}else{dirs[u*max_m+counts[u]]=v;counts[u]++} }
			base:=u*max_m
			for i in 1 .. counts[u] { item:=dirs[base+i];mut j:=i;for j>0&&direction_less(item,dirs[base+j-1]){dirs[base+j]=dirs[base+j-1];j--};dirs[base+j]=item }
			bit_base:=u*bit_stride
			for i in 0 .. counts[u] { mut at:=i+1;for at<=counts[u]{bit[bit_base+at]++;at+=at&-at} }
		}
		mut answers:=[max_q]i64{}
		for qi in 0 .. q {
			ia:=int(queries[qi].a)
			mut ib:=int(queries[qi].b)
			mut ic:=int(queries[qi].c)
			orient:=(a[ib].x-a[ia].x)*(a[ic].y-a[ia].y)-(a[ib].y-a[ia].y)*(a[ic].x-a[ia].x)
			if orient==0{answers[qi]=0;continue};if orient<0{tmp:=ib;ib=ic;ic=tmp}
			outside:=halfplane_count(ia,ib,a[..],dirs[..],counts[..],zeros[..],bit[..])+halfplane_count(ib,ic,a[..],dirs[..],counts[..],zeros[..],bit[..])+halfplane_count(ic,ia,a[..],dirs[..],counts[..],zeros[..],bit[..])
			bs,be:=Vector{x:a[ib].x-a[ic].x,y:a[ib].y-a[ic].y},Vector{x:a[ib].x-a[ia].x,y:a[ib].y-a[ia].y}
			cs,ce:=Vector{x:a[ic].x-a[ia].x,y:a[ic].y-a[ia].y},Vector{x:a[ic].x-a[ib].x,y:a[ic].y-a[ib].y}
			a_start,a_end:=Vector{x:a[ia].x-a[ib].x,y:a[ia].y-a[ib].y},Vector{x:a[ia].x-a[ic].x,y:a[ia].y-a[ic].y}
			pairs:=zeros[ib]+arc_count(dirs[ib*max_m..ib*max_m+counts[ib]],bit[ib*bit_stride..ib*bit_stride+counts[ib]+1],bs,be)+zeros[ic]+arc_count(dirs[ic*max_m..ic*max_m+counts[ic]],bit[ic*bit_stride..ic*bit_stride+counts[ic]+1],cs,ce)+zeros[ia]+arc_count(dirs[ia*max_m..ia*max_m+counts[ia]],bit[ia*bit_stride..ia*bit_stride+counts[ia]+1],a_start,a_end)
			answers[qi]=i64(m-outside+pairs)
		}
		for i in 0 .. q { store_le(mut output,8*i,answers[i]) }
		return i64(required)
	}
}
