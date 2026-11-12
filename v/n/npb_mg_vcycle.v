import math

const side = 4
const cells = 64

fn wrap_index(value int, n int) int {
	if value < 0 { return value + n }
	if value >= n { return value - n }
	return value
}
fn grid_index(x int, y int, z int, n int) int { return x + n * (y + n * z) }
fn stencil(src &f64, mut dst &f64, n int, center f64, face f64, edge f64, corner f64) {
	unsafe {
		for z in 0 .. n { for y in 0 .. n { for x in 0 .. n {
			q := grid_index(x,y,z,n); mut total := center * src[q]
			for dz in -1 .. 2 { for dy in -1 .. 2 { for dx in -1 .. 2 {
				ax := if dx < 0 { -dx } else { dx }; ay := if dy < 0 { -dy } else { dy }; az := if dz < 0 { -dz } else { dz }
				distance := ax + ay + az; if distance == 0 { continue }
				weight := if distance == 1 { face } else if distance == 2 { edge } else { corner }
				neighbor := grid_index(wrap_index(x+dx,n),wrap_index(y+dy,n),wrap_index(z+dz,n),n)
				total += weight * src[neighbor]
			} } }
			dst[q]=total
		} } }
	}
}
fn restrict_grid(fine &f64, n int, mut coarse &f64) {
	unsafe {
		half:=n/2
		for z in 0 .. half { for y in 0 .. half { for x in 0 .. half {
			mut total:=0.0
			for dz in -1 .. 2 { for dy in -1 .. 2 { for dx in -1 .. 2 {
				wx:=if dx==0 {1.0}else{0.5}; wy:=if dy==0 {1.0}else{0.5}; wz:=if dz==0 {1.0}else{0.5}
				q:=grid_index(wrap_index(2*x+dx,n),wrap_index(2*y+dy,n),wrap_index(2*z+dz,n),n)
				total+=wx*wy*wz*fine[q]
			} } }
			coarse[grid_index(x,y,z,half)]=0.5*total
		} } }
	}
}
fn interpolate_grid(coarse &f64, half int, mut fine &f64) {
	unsafe {
		n:=2*half
		for z in 0 .. n { for y in 0 .. n { for x in 0 .. n {
			bx,by,bz:=x/2,y/2,z/2; nx,ny,nz:=1,1,1; wx,wy,wz:=1.0,1.0,1.0
			if x%2==1 {nx=2;wx=0.5}; if y%2==1 {ny=2;wy=0.5}; if z%2==1 {nz=2;wz=0.5}
			mut total:=0.0
			for iz in 0 .. nz { for iy in 0 .. ny { for ix in 0 .. nx {
				total+=wx*wy*wz*coarse[grid_index((bx+ix)%half,(by+iy)%half,(bz+iz)%half,half)]
			} } }
			fine[grid_index(x,y,z,n)]=total
		} } }
	}
}
fn vcycle(rhs &f64, n int, mut solution &f64) {
	unsafe {
		if n==2 { stencil(rhs,solution,n,-3.0/8.0,1.0/32.0,-1.0/64.0,0.0); return }
		half:=n/2
		mut coarse_rhs:=[64]f64{}; mut coarse_solution:=[64]f64{}; mut prolonged:=[64]f64{}; mut applied:=[64]f64{}; mut remaining:=[64]f64{}; mut post:=[64]f64{}
		restrict_grid(rhs,n,&coarse_rhs[0]); vcycle(&coarse_rhs[0],half,&coarse_solution[0]); interpolate_grid(&coarse_solution[0],half,&prolonged[0])
		stencil(&prolonged[0],&applied[0],n,-8.0/3.0,0.0,1.0/6.0,1.0/12.0)
		for q in 0 .. n*n*n { remaining[q]=rhs[q]-applied[q] }
		stencil(&remaining[0],&post[0],n,-3.0/8.0,1.0/32.0,-1.0/64.0,0.0)
		for q in 0 .. n*n*n { solution[q]=prolonged[q]+post[q] }
	}
}

@[export: 'npb_mg_vcycle']
pub fn npb_mg_vcycle(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input==nil || length<2 || length>34 {return -1}
		itv,countv:=input[0],input[1]
		if !itv.is_finite() || !countv.is_finite() || math.trunc(itv)!=itv || math.trunc(countv)!=countv || itv<1 || itv>4 || countv<0 || countv>8 {return -1}
		iterations,sources:=int(itv),int(countv)
		if length!=usize(2+4*sources) {return -1}
		mut rhs:=[64]f64{}; mut seen:=[64]bool{}
		for source in 0 .. sources {
			base:=2+4*source; xv,yv,zv,value:=input[base],input[base+1],input[base+2],input[base+3]
			if !xv.is_finite() || !yv.is_finite() || !zv.is_finite() || !value.is_finite() || math.trunc(xv)!=xv || math.trunc(yv)!=yv || math.trunc(zv)!=zv || xv<0 || xv>=4 || yv<0 || yv>=4 || zv<0 || zv>=4 || value < -4 || value > 4 {return -1}
			q:=grid_index(int(xv),int(yv),int(zv),side); if seen[q] {return -1}; seen[q]=true; rhs[q]=value
		}
		if output==nil || capacity<1 {return -2}
		mut solution:=[64]f64{}; mut applied:=[64]f64{}; mut residual:=[64]f64{}; mut correction:=[64]f64{}
		for _ in 0 .. iterations {
			stencil(&solution[0],&applied[0],side,-8.0/3.0,0.0,1.0/6.0,1.0/12.0)
			for q in 0 .. cells {residual[q]=rhs[q]-applied[q]}
			vcycle(&residual[0],side,&correction[0])
			for q in 0 .. cells {solution[q]+=correction[q]}
		}
		mut checksum:=0.0; for q in 0 .. cells {checksum+=solution[q]}; output[0]=checksum; return 1
	}
}
