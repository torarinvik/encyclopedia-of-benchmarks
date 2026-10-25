package parboil_lbm

import "core:c"

Q :: 19
CELLS :: 27
HALO_CELLS :: 125
DX :: [19]int{0,0,0,1,-1,0,0,1,-1,1,-1,0,0,0,0,1,1,-1,-1}
DY :: [19]int{0,1,-1,0,0,0,0,1,1,-1,-1,1,1,-1,-1,0,0,0,0}
DZ :: [19]int{0,0,0,0,0,1,-1,0,0,0,0,1,-1,1,-1,1,-1,1,-1}
OPP :: [19]int{0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15}

cell_index :: proc "contextless" (x,y,z: int) -> int { return x+3*y+9*z }
halo_index :: proc "contextless" (x,y,z,q: int) -> int { return (((z+1)*5+(y+1))*5+(x+1))*Q+q }

initial_weight :: proc "contextless" (q: int) -> f32 {
	if q == 0 do return f32(1.0/3.0)
	if q <= 6 do return f32(1.0/18.0)
	return f32(1.0/36.0)
}

axis_factor :: proc "contextless" (u: f32, positive: bool, u2: f32) -> f32 {
	product := 4.5 * u
	if positive do product = product + 3.0 else product = product - 3.0
	product = u * product
	product = 1.0 + product
	return product - u2
}

diagonal_factor :: proc "contextless" (cu,u2: f32) -> f32 {
	product := 4.5 * cu
	product = product + 3.0
	product = cu * product
	product = 1.0 + product
	return product - u2
}

collide :: proc "contextless" (source,rho,factor: f32, weight: f64) -> f32 {
	omega: f32 = 1.95
	base := (1.0-omega)*source
	equilibrium := weight*f64(omega)
	equilibrium = equilibrium*f64(rho)
	equilibrium = equilibrium*f64(factor)
	return f32(f64(base)+equilibrium)
}

collide_cell :: proc "contextless" (f: [^]f32, post: [^]f32) {
	rho := f[0]
	for q := 1; q < Q; q += 1 { rho = rho + f[q] }
	ux := f[3]; ux=ux-f[4]; ux=ux+f[7]; ux=ux-f[8]; ux=ux+f[9]; ux=ux-f[10]; ux=ux+f[15]; ux=ux+f[16]; ux=ux-f[17]; ux=ux-f[18]
	uy := f[1]; uy=uy-f[2]; uy=uy+f[7]; uy=uy+f[8]; uy=uy-f[9]; uy=uy-f[10]; uy=uy+f[11]; uy=uy+f[12]; uy=uy-f[13]; uy=uy-f[14]
	uz := f[5]; uz=uz-f[6]; uz=uz+f[11]; uz=uz-f[12]; uz=uz+f[13]; uz=uz-f[14]; uz=uz+f[15]; uz=uz-f[16]; uz=uz+f[17]; uz=uz-f[18]
	ux=ux/rho; uy=uy/rho; uz=uz/rho
	u2 := ux*ux; u2=u2+uy*uy; u2=u2+uz*uz; u2=1.5*u2
	post[0]=collide(f[0],rho,1.0-u2,1.0/3.0)
	post[1]=collide(f[1],rho,axis_factor(uy,true,u2),1.0/18.0)
	post[2]=collide(f[2],rho,axis_factor(uy,false,u2),1.0/18.0)
	post[3]=collide(f[3],rho,axis_factor(ux,true,u2),1.0/18.0)
	post[4]=collide(f[4],rho,axis_factor(ux,false,u2),1.0/18.0)
	post[5]=collide(f[5],rho,axis_factor(uz,true,u2),1.0/18.0)
	post[6]=collide(f[6],rho,axis_factor(uz,false,u2),1.0/18.0)
	cu := ux+uy; post[7]=collide(f[7],rho,diagonal_factor(cu,u2),1.0/36.0)
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

quantize :: proc "contextless" (value: f32) -> i64 {
	scaled := value*1_000_000
	magnitude := if scaled < 0 do -scaled else scaled
	whole := i64(magnitude)
	if magnitude-f32(whole) >= 0.5 do whole += 1
	if scaled < 0 do return -whole
	return whole
}

// Clean-room Parboil D3Q19 profile; Illinois Open Source License is in package docs.
@(export)
parboil_lbm :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 19 do return -1
	nonzero := false
	for q := 0; q < Q; q += 1 {
		if values[q] < 0 || values[q] > 100_000 do return -1
		if values[q] != 0 do nonzero = true
	}
	if !nonzero do return -1

	source: [CELLS*Q]f32 = {}
	destination: [HALO_CELLS*Q]f32 = {}
	for z := 0; z < 3; z += 1 { for y := 0; y < 3; y += 1 { for x := 0; x < 3; x += 1 {
		cell := cell_index(x,y,z)
		for q := 0; q < Q; q += 1 {
			weight := initial_weight(q)
			source[cell*Q+q]=weight
			destination[halo_index(x,y,z,q)]=weight
		}
	} } }
	for q := 0; q < Q; q += 1 { source[cell_index(1,1,1)*Q+q]=f32(values[q])/1_000_000 }

	for z := 0; z < 3; z += 1 { for y := 0; y < 3; y += 1 { for x := 0; x < 3; x += 1 {
		cell := cell_index(x,y,z)
		obstacle := x==0 || x==2 || y==0 || y==2 || z==0 || z==2
		post: [Q]f32 = {}
		if !obstacle do collide_cell(&source[cell*Q], &post[0])
		for q := 0; q < Q; q += 1 {
			outgoing := if obstacle do source[cell*Q+OPP[q]] else post[q]
			destination[halo_index(x+DX[q],y+DY[q],z+DZ[q],q)] = outgoing
		}
	} } }

	checksum: i64 = 0
	for z := 0; z < 3; z += 1 { for y := 0; y < 3; y += 1 { for x := 0; x < 3; x += 1 {
		cell := cell_index(x,y,z)
		for q := 0; q < Q; q += 1 { checksum += i64(cell+1)*quantize(destination[halo_index(x,y,z,q)]) }
	} } }
	return checksum
}
