const Q: usize = 19;
const CELLS: usize = 27;
const HALO_CELLS: usize = 125;
const DX: [i32; Q] = [0,0,0,1,-1,0,0,1,-1,1,-1,0,0,0,0,1,1,-1,-1];
const DY: [i32; Q] = [0,1,-1,0,0,0,0,1,1,-1,-1,1,1,-1,-1,0,0,0,0];
const DZ: [i32; Q] = [0,0,0,0,0,1,-1,0,0,0,0,1,-1,1,-1,1,-1,1,-1];
const OPP: [usize; Q] = [0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15];

fn cell_index(x: usize, y: usize, z: usize) -> usize { x + 3*y + 9*z }
fn halo_index(x: i32, y: i32, z: i32, q: usize) -> usize {
    ((((z + 1) * 5 + (y + 1)) * 5 + (x + 1)) as usize) * Q + q
}

fn initial_weight(q: usize) -> f32 {
    if q == 0 { (1.0 / 3.0) as f32 }
    else if q <= 6 { (1.0 / 18.0) as f32 }
    else { (1.0 / 36.0) as f32 }
}

fn axis_factor(u: f32, positive: bool, u2: f32) -> f32 {
    let mut product = 4.5_f32 * u;
    product = if positive { product + 3.0_f32 } else { product - 3.0_f32 };
    product = u * product;
    product = 1.0_f32 + product;
    product - u2
}

fn diagonal_factor(cu: f32, u2: f32) -> f32 {
    let mut product = 4.5_f32 * cu;
    product = product + 3.0_f32;
    product = cu * product;
    product = 1.0_f32 + product;
    product - u2
}

fn collide(source: f32, rho: f32, factor: f32, weight: f64) -> f32 {
    let omega = 1.95_f32;
    let base = (1.0_f32 - omega) * source;
    let mut equilibrium = weight * f64::from(omega);
    equilibrium = equilibrium * f64::from(rho);
    equilibrium = equilibrium * f64::from(factor);
    (f64::from(base) + equilibrium) as f32
}

fn collide_cell(f: &[f32; Q], post: &mut [f32; Q]) {
    let mut rho = f[0];
    for q in 1..Q { rho = rho + f[q]; }
    let mut ux = f[3];
    ux=ux-f[4]; ux=ux+f[7]; ux=ux-f[8]; ux=ux+f[9]; ux=ux-f[10];
    ux=ux+f[15]; ux=ux+f[16]; ux=ux-f[17]; ux=ux-f[18];
    let mut uy = f[1];
    uy=uy-f[2]; uy=uy+f[7]; uy=uy+f[8]; uy=uy-f[9]; uy=uy-f[10];
    uy=uy+f[11]; uy=uy+f[12]; uy=uy-f[13]; uy=uy-f[14];
    let mut uz = f[5];
    uz=uz-f[6]; uz=uz+f[11]; uz=uz-f[12]; uz=uz+f[13]; uz=uz-f[14];
    uz=uz+f[15]; uz=uz-f[16]; uz=uz+f[17]; uz=uz-f[18];
    ux=ux/rho; uy=uy/rho; uz=uz/rho;
    let mut u2=ux*ux;
    u2=u2+uy*uy;
    u2=u2+uz*uz;
    u2=1.5_f32*u2;
    post[0]=collide(f[0],rho,1.0_f32-u2,1.0/3.0);
    post[1]=collide(f[1],rho,axis_factor(uy,true,u2),1.0/18.0);
    post[2]=collide(f[2],rho,axis_factor(uy,false,u2),1.0/18.0);
    post[3]=collide(f[3],rho,axis_factor(ux,true,u2),1.0/18.0);
    post[4]=collide(f[4],rho,axis_factor(ux,false,u2),1.0/18.0);
    post[5]=collide(f[5],rho,axis_factor(uz,true,u2),1.0/18.0);
    post[6]=collide(f[6],rho,axis_factor(uz,false,u2),1.0/18.0);
    let mut cu=ux+uy; post[7]=collide(f[7],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux+uy; post[8]=collide(f[8],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=ux-uy; post[9]=collide(f[9],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux-uy; post[10]=collide(f[10],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=uy+uz; post[11]=collide(f[11],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=uy-uz; post[12]=collide(f[12],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-uy+uz; post[13]=collide(f[13],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-uy-uz; post[14]=collide(f[14],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=ux+uz; post[15]=collide(f[15],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=ux-uz; post[16]=collide(f[16],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux+uz; post[17]=collide(f[17],rho,diagonal_factor(cu,u2),1.0/36.0);
    cu=-ux-uz; post[18]=collide(f[18],rho,diagonal_factor(cu,u2),1.0/36.0);
}

fn quantize(value: f32) -> i64 { (value * 1_000_000_f32).round() as i64 }

/// Clean-room Parboil D3Q19 profile; see package docs for the Illinois Open Source License.
#[no_mangle]
pub unsafe extern "C" fn parboil_lbm(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != Q { return -1; }
    let values = std::slice::from_raw_parts(input, Q);
    if values.iter().any(|v| *v < 0 || *v > 100_000) || values.iter().all(|v| *v == 0) { return -1; }

    let mut source = [0.0_f32; CELLS * Q];
    let mut destination = [0.0_f32; HALO_CELLS * Q];
    for z in 0..3 { for y in 0..3 { for x in 0..3 {
        let cell = cell_index(x,y,z);
        for q in 0..Q {
            let weight = initial_weight(q);
            source[cell*Q+q] = weight;
            destination[halo_index(x as i32,y as i32,z as i32,q)] = weight;
        }
    } } }
    for q in 0..Q { source[cell_index(1,1,1)*Q+q] = values[q] as f32 / 1_000_000_f32; }

    for z in 0..3 { for y in 0..3 { for x in 0..3 {
        let cell = cell_index(x,y,z);
        let obstacle = x==0 || x==2 || y==0 || y==2 || z==0 || z==2;
        let mut post = [0.0_f32; Q];
        if !obstacle {
            let mut local = [0.0_f32; Q];
            local.copy_from_slice(&source[cell*Q..cell*Q+Q]);
            collide_cell(&local, &mut post);
        }
        for q in 0..Q {
            let outgoing = if obstacle { source[cell*Q+OPP[q]] } else { post[q] };
            destination[halo_index(x as i32+DX[q],y as i32+DY[q],z as i32+DZ[q],q)] = outgoing;
        }
    } } }

    let mut checksum = 0_i64;
    for z in 0..3 { for y in 0..3 { for x in 0..3 {
        let cell = cell_index(x,y,z);
        for q in 0..Q { checksum += (cell as i64 + 1) * quantize(destination[halo_index(x as i32,y as i32,z as i32,q)]); }
    } } }
    checksum
}
