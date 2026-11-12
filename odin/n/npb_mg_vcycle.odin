package npb_mg_vcycle

import "core:c"
import "core:math"

SIDE :: 4
CELLS :: 64
MAX_SOURCES :: 8

wrap_index :: proc "contextless" (value, side: int) -> int {
	if value < 0 do return value + side
	if value >= side do return value - side
	return value
}
grid_index :: proc "contextless" (x, y, z, side: int) -> int { return x + side*(y + side*z) }
stencil :: proc "contextless" (src, dst: [^]f64, side: int, center, face, edge, corner: f64) {
	for z := 0; z < side; z += 1 { for y := 0; y < side; y += 1 { for x := 0; x < side; x += 1 {
		q := grid_index(x,y,z,side); total := center*src[q]
		for dz := -1; dz <= 1; dz += 1 { for dy := -1; dy <= 1; dy += 1 { for dx := -1; dx <= 1; dx += 1 {
			distance := math.abs(dx)+math.abs(dy)+math.abs(dz); if distance == 0 do continue
			weight := face; if distance == 2 do weight = edge; if distance == 3 do weight = corner
			neighbor := grid_index(wrap_index(x+dx,side),wrap_index(y+dy,side),wrap_index(z+dz,side),side)
			total += weight*src[neighbor]
		} } }
		dst[q] = total
	} } }
}
restrict_grid :: proc "contextless" (fine: [^]f64, side: int, coarse: [^]f64) {
	half := side/2
	for z := 0; z < half; z += 1 { for y := 0; y < half; y += 1 { for x := 0; x < half; x += 1 {
		total: f64 = 0
		for dz := -1; dz <= 1; dz += 1 { for dy := -1; dy <= 1; dy += 1 { for dx := -1; dx <= 1; dx += 1 {
			wx, wy, wz := f64(0.5), f64(0.5), f64(0.5); if dx == 0 do wx=1; if dy == 0 do wy=1; if dz == 0 do wz=1
			q := grid_index(wrap_index(2*x+dx,side),wrap_index(2*y+dy,side),wrap_index(2*z+dz,side),side)
			total += wx*wy*wz*fine[q]
		} } }
		coarse[grid_index(x,y,z,half)] = 0.5*total
	} } }
}
interpolate_grid :: proc "contextless" (coarse: [^]f64, half: int, fine: [^]f64) {
	side := 2*half
	for z := 0; z < side; z += 1 { for y := 0; y < side; y += 1 { for x := 0; x < side; x += 1 {
		bx,by,bz := x/2,y/2,z/2; nx,ny,nz := 1,1,1; wx,wy,wz := f64(1),f64(1),f64(1)
		if x%2 == 1 { nx=2; wx=0.5 }
		if y%2 == 1 { ny=2; wy=0.5 }
		if z%2 == 1 { nz=2; wz=0.5 }
		total: f64 = 0
		for iz := 0; iz < nz; iz += 1 { for iy := 0; iy < ny; iy += 1 { for ix := 0; ix < nx; ix += 1 {
			total += wx*wy*wz*coarse[grid_index((bx+ix)%half,(by+iy)%half,(bz+iz)%half,half)]
		} } }
		fine[grid_index(x,y,z,side)] = total
	} } }
}
vcycle :: proc "contextless" (rhs: [^]f64, side: int, solution: [^]f64) {
	if side == 2 { stencil(rhs,solution,side,-3.0/8.0,1.0/32.0,-1.0/64.0,0); return }
	half := side/2
	var coarse_rhs, coarse_solution, prolonged, applied, remaining, post: [CELLS]f64
	restrict_grid(rhs,side,&coarse_rhs[0]); vcycle(&coarse_rhs[0],half,&coarse_solution[0]); interpolate_grid(&coarse_solution[0],half,&prolonged[0])
	stencil(&prolonged[0],&applied[0],side,-8.0/3.0,0,1.0/6.0,1.0/12.0)
	count := side*side*side
	for q := 0; q < count; q += 1 { remaining[q]=rhs[q]-applied[q] }
	stencil(&remaining[0],&post[0],side,-3.0/8.0,1.0/32.0,-1.0/64.0,0)
	for q := 0; q < count; q += 1 { solution[q]=prolonged[q]+post[q] }
}

@(export)
npb_mg_vcycle :: proc "c" (input: [^]f64, length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 34 do return -1
	itv,countv := input[0],input[1]
	if itv != itv || countv != countv || math.trunc(itv) != itv || math.trunc(countv) != countv || itv < 1 || itv > 4 || countv < 0 || countv > f64(MAX_SOURCES) do return -1
	iterations,sources := int(itv),int(countv)
	if length != c.size_t(2+4*sources) do return -1
	var rhs, solution, applied, residual, correction: [CELLS]f64
	var seen: [CELLS]bool
	for source := 0; source < sources; source += 1 {
		base := 2+4*source; xv,yv,zv,value := input[base],input[base+1],input[base+2],input[base+3]
		if xv != xv || yv != yv || zv != zv || math.trunc(xv) != xv || math.trunc(yv) != yv || math.trunc(zv) != zv || xv < 0 || xv >= f64(SIDE) || yv < 0 || yv >= f64(SIDE) || zv < 0 || zv >= f64(SIDE) || value != value || value < -4 || value > 4 do return -1
		q := grid_index(int(xv),int(yv),int(zv),SIDE); if seen[q] do return -1; seen[q]=true; rhs[q]=value
	}
	if output == nil || capacity < 1 do return -2
	for _ := 0; _ < iterations; _ += 1 {
		stencil(&solution[0],&applied[0],SIDE,-8.0/3.0,0,1.0/6.0,1.0/12.0)
		for q := 0; q < CELLS; q += 1 { residual[q]=rhs[q]-applied[q] }
		vcycle(&residual[0],SIDE,&correction[0])
		for q := 0; q < CELLS; q += 1 { solution[q]+=correction[q] }
	}
	checksum:f64=0; for q := 0; q < CELLS; q += 1 { checksum+=solution[q] }
	output[0]=checksum; return 1
}
