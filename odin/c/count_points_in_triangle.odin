package count_points_in_triangle

import "core:c"

MAX_N :: 24
MAX_M :: 24
MAX_Q :: 128
INPUT_MAX :: 483
BIT_STRIDE :: MAX_M + 1

Point :: struct { x, y: i64 }
Vector :: struct { x, y: i64 }
Query :: struct { a, b, c: i64 }

half :: proc(v: Vector) -> int { if v.y < 0 { return 0 }; if v.y == 0 && v.x >= 0 { return 1 }; return 2 }
angle_less :: proc(a, b: Vector) -> bool {
	ha, hb := half(a), half(b)
	if ha != hb { return ha < hb }
	return a.x*b.y-a.y*b.x > 0
}
direction_less :: proc(a, b: Vector) -> bool {
	if angle_less(a,b) { return true }; if angle_less(b,a) { return false }
	ra, rb := a.x*a.x+a.y*a.y, b.x*b.x+b.y*b.y
	if ra != rb { return ra < rb }; if a.x != b.x { return a.x < b.x }; return a.y < b.y
}
sort_vectors :: proc(dirs: [^]Vector, base, count: int) {
	for i := 1; i < count; i += 1 {
		item := dirs[base+i]; j := i
		for j > 0 && direction_less(item, dirs[base+j-1]) { dirs[base+j]=dirs[base+j-1]; j -= 1 }
		dirs[base+j]=item
	}
}
lower_ray :: proc(dirs: [^]Vector, base, count: int, ray: Vector) -> int {
	low, high := 0, count
	for low < high { middle := low+(high-low)/2; if angle_less(dirs[base+middle],ray) { low=middle+1 } else { high=middle } }
	return low
}
upper_ray :: proc(dirs: [^]Vector, base, count: int, ray: Vector) -> int {
	low, high := 0, count
	for low < high { middle := low+(high-low)/2; if !angle_less(ray,dirs[base+middle]) { low=middle+1 } else { high=middle } }
	return low
}
fenwick_prefix :: proc(bit: [^]i32, base, end: int) -> int {
	total := 0; cursor := end
	for cursor > 0 { total += int(bit[base+cursor]); cursor &= cursor-1 }
	return total
}
arc_count :: proc(dirs: [^]Vector, dir_base, count: int, bit: [^]i32, bit_base: int, start, end: Vector) -> int {
	left := lower_ray(dirs,dir_base,count,start); right := upper_ray(dirs,dir_base,count,end)
	if !angle_less(end,start) { return fenwick_prefix(bit,bit_base,right)-fenwick_prefix(bit,bit_base,left) }
	return fenwick_prefix(bit,bit_base,count)-fenwick_prefix(bit,bit_base,left)+fenwick_prefix(bit,bit_base,right)
}
halfplane_count :: proc(u, v: int, a: [^]Point, dirs: [^]Vector, counts: [^]int, zeros: [^]int, bit: [^]i32) -> int {
	edge := Vector{a[v].x-a[u].x,a[v].y-a[u].y}
	return zeros[u]+arc_count(dirs,u*MAX_M,counts[u],bit,u*BIT_STRIDE,Vector{-edge.x,-edge.y},edge)
}
store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte]=u8((bits>>(8*byte))&255) }
}

@(export)
count_points_in_triangle :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(INPUT_MAX) { return -1 }
	nr,mr,qr := input[0],input[1],input[2]
	if nr < 1 || nr > MAX_N || mr < 1 || mr > MAX_M || qr < 1 || qr > MAX_Q { return -1 }
	n,m,q := int(nr),int(mr),int(qr)
	if int(length) != 3+2*n+2*m+3*q { return -1 }
	a: [MAX_N]Point; b: [MAX_M]Point; queries: [MAX_Q]Query
	cursor := 3
	for i := 0; i < n; i += 1 { a[i]=Point{input[cursor],input[cursor+1]}; cursor+=2; if a[i].x < -1_000_000_000 || a[i].x > 1_000_000_000 || a[i].y < -1_000_000_000 || a[i].y > 1_000_000_000 { return -1 } }
	for i := 0; i < m; i += 1 { b[i]=Point{input[cursor],input[cursor+1]}; cursor+=2; if b[i].x < -1_000_000_000 || b[i].x > 1_000_000_000 || b[i].y < -1_000_000_000 || b[i].y > 1_000_000_000 { return -1 } }
	for i := 0; i < q; i += 1 { ia,ib,ic := input[cursor],input[cursor+1],input[cursor+2]; cursor+=3; if ia < 0 || ia >= nr || ib < 0 || ib >= nr || ic < 0 || ic >= nr { return -1 }; queries[i]=Query{ia,ib,ic} }
	required := c.size_t(8*q); if output == nil || capacity < required { return -2 }
	dirs: [MAX_N*MAX_M]Vector; counts: [MAX_N]int; zeros: [MAX_N]int; bit: [MAX_N*BIT_STRIDE]i32
	for u := 0; u < n; u += 1 {
		for j := 0; j < m; j += 1 { v:=Vector{b[j].x-a[u].x,b[j].y-a[u].y}; if v.x==0 && v.y==0 { zeros[u]+=1 } else { dirs[u*MAX_M+counts[u]]=v; counts[u]+=1 } }
		sort_vectors(&dirs[0],u*MAX_M,counts[u])
		for i := 0; i < counts[u]; i += 1 { at:=i+1; for at <= counts[u] { bit[u*BIT_STRIDE+at]+=1; at += at & -at } }
	}
	answers: [MAX_Q]i64
	for qi := 0; qi < q; qi += 1 {
		ia,ib,ic := int(queries[qi].a),int(queries[qi].b),int(queries[qi].c)
		orient := (a[ib].x-a[ia].x)*(a[ic].y-a[ia].y)-(a[ib].y-a[ia].y)*(a[ic].x-a[ia].x)
		if orient==0 { answers[qi]=0; continue }; if orient<0 { ib,ic=ic,ib }
		outside := halfplane_count(ia,ib,&a[0],&dirs[0],&counts[0],&zeros[0],&bit[0])+halfplane_count(ib,ic,&a[0],&dirs[0],&counts[0],&zeros[0],&bit[0])+halfplane_count(ic,ia,&a[0],&dirs[0],&counts[0],&zeros[0],&bit[0])
		bs,be:=Vector{a[ib].x-a[ic].x,a[ib].y-a[ic].y},Vector{a[ib].x-a[ia].x,a[ib].y-a[ia].y}
		cs,ce:=Vector{a[ic].x-a[ia].x,a[ic].y-a[ia].y},Vector{a[ic].x-a[ib].x,a[ic].y-a[ib].y}
		a_start,a_end:=Vector{a[ia].x-a[ib].x,a[ia].y-a[ib].y},Vector{a[ia].x-a[ic].x,a[ia].y-a[ic].y}
		pairs:=zeros[ib]+arc_count(&dirs[0],ib*MAX_M,counts[ib],&bit[0],ib*BIT_STRIDE,bs,be)+zeros[ic]+arc_count(&dirs[0],ic*MAX_M,counts[ic],&bit[0],ic*BIT_STRIDE,cs,ce)+zeros[ia]+arc_count(&dirs[0],ia*MAX_M,counts[ia],&bit[0],ia*BIT_STRIDE,a_start,a_end)
		answers[qi]=i64(m-outside+pairs)
	}
	for i := 0; i < q; i += 1 { store_le(output,8*i,answers[i]) }
	return i64(required)
}
