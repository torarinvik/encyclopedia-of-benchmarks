package npb_lu_block_ssor

import "core:c"
import "core:math"

MAX_POINTS :: 32
MAX_MICRO: i64 : 1_000_000_000
SCALE: f64 : 1_000_000.0

write_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(8*byte)) }
}

solve5 :: proc(d, rhs, result: [^]f64) -> bool {
	var a: [25]f64
	var b: [5]f64
	for i := 0; i < 25; i += 1 { a[i] = d[i] }
	for i := 0; i < 5; i += 1 { b[i] = rhs[i] }
	for pivot := 0; pivot < 5; pivot += 1 {
		divisor := a[pivot*5+pivot]
		if divisor <= 0 do return false
		for row := pivot+1; row < 5; row += 1 {
			factor := a[row*5+pivot]/divisor
			for column := pivot+1; column < 5; column += 1 { a[row*5+column] -= factor*a[pivot*5+column] }
			b[row] -= factor*b[pivot]
		}
	}
	for back := 0; back < 5; back += 1 {
		row := 4-back
		tail: f64 = 0
		for column := row+1; column < 5; column += 1 { tail += a[row*5+column]*result[column] }
		result[row] = (b[row]-tail)/a[row*5+row]
	}
	return true
}

apply_operator :: proc(nx, ny, nz: int, d, c, x, out: [^]f64) {
	points := nx*ny*nz
	nxy := nx*ny
	for point := 0; point < points; point += 1 {
		ix, iy, iz := point%nx, (point/nx)%ny, point/nxy
		for row := 0; row < 5; row += 1 {
			total: f64 = 0
			for column := 0; column < 5; column += 1 { total += d[row*5+column]*x[point*5+column] }
			if ix > 0 do total += c[0]*x[(point-1)*5+row]
			if ix+1 < nx do total += c[0]*x[(point+1)*5+row]
			if iy > 0 do total += c[1]*x[(point-nx)*5+row]
			if iy+1 < ny do total += c[1]*x[(point+nx)*5+row]
			if iz > 0 do total += c[2]*x[(point-nxy)*5+row]
			if iz+1 < nz do total += c[2]*x[(point+nxy)*5+row]
			out[point*5+row] = total
		}
	}
}

valid :: proc(v: [^]i64, length: c.size_t) -> bool {
	if v == nil || length < 42 || length > 352 do return false
	if v[0] < 1 || v[0] > 4 || v[1] < 1 || v[1] > 4 || v[2] < 1 || v[2] > 4 || v[3] < 1 || v[3] > 8 do return false
	nx, ny, nz := int(v[0]), int(v[1]), int(v[2])
	points := nx*ny*nz
	if points > MAX_POINTS || int(length) != 32+10*points do return false
	for i := 4; i < int(length); i += 1 { if v[i] < -MAX_MICRO || v[i] > MAX_MICRO do return false }
	for row := 0; row < 5; row += 1 {
		diagonal := v[4+row*5+row]
		off_sum: i64 = 0
		for column := 0; column < 5; column += 1 {
			entry := v[4+row*5+column]
			if entry != v[4+column*5+row] do return false
			if column != row { if entry < 0 do off_sum -= entry else do off_sum += entry }
		}
		if nx > 1 { if v[29] < 0 do off_sum -= 2*v[29] else do off_sum += 2*v[29] }
		if ny > 1 { if v[30] < 0 do off_sum -= 2*v[30] else do off_sum += 2*v[30] }
		if nz > 1 { if v[31] < 0 do off_sum -= 2*v[31] else do off_sum += 2*v[31] }
		if diagonal <= 0 || diagonal <= off_sum do return false
	}
	return true
}

@(export)
npb_lu_block_ssor :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if !valid(input,length) do return -1
	nx,ny,nz,sweeps := int(input[0]),int(input[1]),int(input[2]),int(input[3])
	points,count := nx*ny*nz,5*nx*ny*nz
	output_bytes := 8*(sweeps+count)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	var d: [25]f64
	var c: [3]f64
	var x,rhs,applied,residual,forward,correction: [MAX_POINTS*5]f64
	for i := 0; i < 25; i += 1 { d[i] = f64(input[4+i])/SCALE }
	for axis := 0; axis < 3; axis += 1 { c[axis] = f64(input[29+axis])/SCALE }
	for i := 0; i < count; i += 1 { rhs[i]=f64(input[32+i])/SCALE; x[i]=f64(input[32+count+i])/SCALE }
	nxy := nx*ny
	for sweep := 0; sweep < sweeps; sweep += 1 {
		apply_operator(nx,ny,nz,&d[0],&c[0],&x[0],&applied[0])
		for i := 0; i < count; i += 1 { residual[i]=rhs[i]-applied[i] }
		for point := 0; point < points; point += 1 {
			ix,iy,iz := point%nx,(point/nx)%ny,point/nxy
			var local,solved: [5]f64
			for row := 0; row < 5; row += 1 { local[row]=residual[point*5+row] }
			if ix>0 { for row:=0;row<5;row+=1 { local[row]-=c[0]*forward[(point-1)*5+row] } }
			if iy>0 { for row:=0;row<5;row+=1 { local[row]-=c[1]*forward[(point-nx)*5+row] } }
			if iz>0 { for row:=0;row<5;row+=1 { local[row]-=c[2]*forward[(point-nxy)*5+row] } }
			if !solve5(&d[0],&local[0],&solved[0]) do return -1
			for row:=0;row<5;row+=1 { forward[point*5+row]=solved[row] }
		}
		for back:=0;back<points;back+=1 {
			point:=points-1-back; ix,iy,iz:=point%nx,(point/nx)%ny,point/nxy
			var local,solved: [5]f64
			for row:=0;row<5;row+=1 { for column:=0;column<5;column+=1 { local[row]+=d[row*5+column]*forward[point*5+column] } }
			if ix+1<nx { for row:=0;row<5;row+=1 { local[row]-=c[0]*correction[(point+1)*5+row] } }
			if iy+1<ny { for row:=0;row<5;row+=1 { local[row]-=c[1]*correction[(point+nx)*5+row] } }
			if iz+1<nz { for row:=0;row<5;row+=1 { local[row]-=c[2]*correction[(point+nxy)*5+row] } }
			if !solve5(&d[0],&local[0],&solved[0]) do return -1
			for row:=0;row<5;row+=1 { correction[point*5+row]=solved[row] }
		}
		for i:=0;i<count;i+=1 { x[i]+=correction[i] }
		apply_operator(nx,ny,nz,&d[0],&c[0],&x[0],&applied[0])
		norm2:f64=0
		for i:=0;i<count;i+=1 { difference:=rhs[i]-applied[i]; norm2+=difference*difference }
		write_f64_le(output,sweep*8,math.sqrt_f64(norm2))
	}
	for i:=0;i<count;i+=1 { write_f64_le(output,(sweeps+i)*8,x[i]) }
	return i64(output_bytes)
}
