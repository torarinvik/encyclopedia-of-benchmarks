module parboil_lbm

const q = 19
const cells = 27
const halo_cells = 125
const dx = [19]int{0,0,0,1,-1,0,0,1,-1,1,-1,0,0,0,0,1,1,-1,-1}
const dy = [19]int{0,1,-1,0,0,0,0,1,1,-1,-1,1,1,-1,-1,0,0,0,0}
const dz = [19]int{0,0,0,0,0,1,-1,0,0,0,0,1,-1,1,-1,1,-1,1,-1}
const opp = [19]int{0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15}

fn cell_index(x int, y int, z int) int { return x + 3*y + 9*z }
fn halo_index(x int, y int, z int, direction int) int {
	return (((z+1)*5+(y+1))*5+(x+1))*q+direction
}
fn initial_weight(direction int) f32 {
	if direction == 0 { return f32(1.0/3.0) }
	if direction <= 6 { return f32(1.0/18.0) }
	return f32(1.0/36.0)
}
fn axis_factor(u f32, positive bool, u2 f32) f32 {
	mut product := f32(4.5) * u
	if positive { product = product + f32(3.0) } else { product = product - f32(3.0) }
	product = u * product
	product = f32(1.0) + product
	return product - u2
}
fn diagonal_factor(cu f32, u2 f32) f32 {
	mut product := f32(4.5) * cu
	product = product + f32(3.0)
	product = cu * product
	product = f32(1.0) + product
	return product - u2
}
fn collide(source f32, rho f32, factor f32, weight f64) f32 {
	omega := f32(1.95)
	base := (f32(1.0)-omega)*source
	mut equilibrium := weight*f64(omega)
	equilibrium = equilibrium*f64(rho)
	equilibrium = equilibrium*f64(factor)
	return f32(f64(base)+equilibrium)
}
fn collide_cell(f &f32, post &f32) {
	mut rho := f[0]
	for direction in 1 .. q { rho = rho + f[direction] }
	mut ux := f[3]
	ux=ux-f[4]; ux=ux+f[7]; ux=ux-f[8]; ux=ux+f[9]; ux=ux-f[10]; ux=ux+f[15]; ux=ux+f[16]; ux=ux-f[17]; ux=ux-f[18]
	mut uy := f[1]
	uy=uy-f[2]; uy=uy+f[7]; uy=uy+f[8]; uy=uy-f[9]; uy=uy-f[10]; uy=uy+f[11]; uy=uy+f[12]; uy=uy-f[13]; uy=uy-f[14]
	mut uz := f[5]
	uz=uz-f[6]; uz=uz+f[11]; uz=uz-f[12]; uz=uz+f[13]; uz=uz-f[14]; uz=uz+f[15]; uz=uz-f[16]; uz=uz+f[17]; uz=uz-f[18]
	ux=ux/rho; uy=uy/rho; uz=uz/rho
	mut u2 := ux*ux
	u2=u2+uy*uy; u2=u2+uz*uz; u2=f32(1.5)*u2
	post[0]=collide(f[0],rho,f32(1)-u2,1.0/3.0)
	post[1]=collide(f[1],rho,axis_factor(uy,true,u2),1.0/18.0)
	post[2]=collide(f[2],rho,axis_factor(uy,false,u2),1.0/18.0)
	post[3]=collide(f[3],rho,axis_factor(ux,true,u2),1.0/18.0)
	post[4]=collide(f[4],rho,axis_factor(ux,false,u2),1.0/18.0)
	post[5]=collide(f[5],rho,axis_factor(uz,true,u2),1.0/18.0)
	post[6]=collide(f[6],rho,axis_factor(uz,false,u2),1.0/18.0)
	mut cu := ux+uy; post[7]=collide(f[7],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=-ux+uy; post[8]=collide(f[8],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=ux-uy; post[9]=collide(f[9],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=-ux-uy; post[10]=collide(f[10],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=uy+uz; post[11]=collide(f[11],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=uy-uz; post[12]=collide(f[12],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=-uy+uz; post[13]=collide(f[13],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=-uy-uz; post[14]=collide(f[14],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=ux+uz; post[15]=collide(f[15],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=ux-uz; post[16]=collide(f[16],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=-ux+uz; post[17]=collide(f[17],rho,diagonal_factor(cu,u2),1.0/36.0)
	cu=-ux-uz; post[18]=collide(f[18],rho,diagonal_factor(cu,u2),1.0/36.0)
}

fn quantize(value f32) i64 {
	scaled := value*f32(1_000_000)
	magnitude := if scaled < 0 { -scaled } else { scaled }
	mut whole := i64(magnitude)
	if magnitude-f32(whole) >= f32(0.5) { whole++ }
	if scaled < 0 { return -whole }
	return whole
}

// Clean-room Parboil D3Q19 profile; Illinois Open Source License is in package docs.
@[export: 'parboil_lbm']
pub fn parboil_lbm(values &i64, length usize) i64 {
	if unsafe { values == nil } || length != q { return -1 }
	unsafe {
		mut nonzero := false
		for direction in 0 .. q {
			if values[direction] < 0 || values[direction] > 100_000 { return -1 }
			if values[direction] != 0 { nonzero = true }
		}
		if !nonzero { return -1 }

		mut source := [cells*q]f32{}
		mut destination := [halo_cells*q]f32{}
		for z in 0 .. 3 { for y in 0 .. 3 { for x in 0 .. 3 {
			cell := cell_index(x,y,z)
			for direction in 0 .. q {
				weight := initial_weight(direction)
				source[cell*q+direction] = weight
				destination[halo_index(x,y,z,direction)] = weight
			}
		} } }
		for direction in 0 .. q { source[cell_index(1,1,1)*q+direction] = f32(values[direction])/1_000_000.0 }

		for z in 0 .. 3 { for y in 0 .. 3 { for x in 0 .. 3 {
			cell := cell_index(x,y,z)
			obstacle := x==0 || x==2 || y==0 || y==2 || z==0 || z==2
			mut post := [q]f32{}
			if !obstacle { collide_cell(&source[cell*q], &post[0]) }
			for direction in 0 .. q {
				outgoing := if obstacle { source[cell*q+opp[direction]] } else { post[direction] }
				destination[halo_index(x+dx[direction],y+dy[direction],z+dz[direction],direction)] = outgoing
			}
		} } }

		mut checksum := i64(0)
		for z in 0 .. 3 { for y in 0 .. 3 { for x in 0 .. 3 {
			cell := cell_index(x,y,z)
			for direction in 0 .. q {
				checksum += i64(cell+1)*quantize(destination[halo_index(x,y,z,direction)])
			}
		} } }
		return checksum
	}
}
