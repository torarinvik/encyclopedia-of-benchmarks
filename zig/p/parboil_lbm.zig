const Q: usize = 19;
const CELLS: usize = 27;
const HALO_CELLS: usize = 125;
const DX = [_]i32{0,0,0,1,-1,0,0,1,-1,1,-1,0,0,0,0,1,1,-1,-1};
const DY = [_]i32{0,1,-1,0,0,0,0,1,1,-1,-1,1,1,-1,-1,0,0,0,0};
const DZ = [_]i32{0,0,0,0,0,1,-1,0,0,0,0,1,-1,1,-1,1,-1,1,-1};
const OPP = [_]usize{0,2,1,4,3,6,5,10,9,8,7,14,13,12,11,18,17,16,15};

fn cellIndex(x: usize, y: usize, z: usize) usize { return x + 3*y + 9*z; }
fn haloIndex(x: i32, y: i32, z: i32, q: usize) usize {
    return @as(usize, @intCast((((z+1)*5+(y+1))*5+(x+1)))) * Q + q;
}
fn initialWeight(q: usize) f32 {
    if (q == 0) return @floatCast(1.0/3.0);
    if (q <= 6) return @floatCast(1.0/18.0);
    return @floatCast(1.0/36.0);
}
fn axisFactor(u: f32, positive: bool, u2: f32) f32 {
    var product = 4.5 * u;
    product = if (positive) product + 3.0 else product - 3.0;
    product = u * product;
    product = 1.0 + product;
    return product - u2;
}
fn diagonalFactor(cu: f32, u2: f32) f32 {
    var product = 4.5 * cu;
    product = product + 3.0;
    product = cu * product;
    product = 1.0 + product;
    return product - u2;
}
fn collide(source: f32, rho: f32, factor: f32, weight: f64) f32 {
    const omega: f32 = 1.95;
    const base = (1.0 - omega) * source;
    var equilibrium = weight * @as(f64, omega);
    equilibrium = equilibrium * @as(f64, rho);
    equilibrium = equilibrium * @as(f64, factor);
    return @floatCast(@as(f64, base) + equilibrium);
}
fn collideCell(f: []const f32, post: []f32) void {
    var rho = f[0];
    for (1..Q) |q| rho = rho + f[q];
    var ux = f[3];
    ux=ux-f[4]; ux=ux+f[7]; ux=ux-f[8]; ux=ux+f[9]; ux=ux-f[10]; ux=ux+f[15]; ux=ux+f[16]; ux=ux-f[17]; ux=ux-f[18];
    var uy = f[1];
    uy=uy-f[2]; uy=uy+f[7]; uy=uy+f[8]; uy=uy-f[9]; uy=uy-f[10]; uy=uy+f[11]; uy=uy+f[12]; uy=uy-f[13]; uy=uy-f[14];
    var uz = f[5];
    uz=uz-f[6]; uz=uz+f[11]; uz=uz-f[12]; uz=uz+f[13]; uz=uz-f[14]; uz=uz+f[15]; uz=uz-f[16]; uz=uz+f[17]; uz=uz-f[18];
    ux=ux/rho; uy=uy/rho; uz=uz/rho;
    var speed_sq=ux*ux; speed_sq=speed_sq+uy*uy; speed_sq=speed_sq+uz*uz; speed_sq=1.5*speed_sq;
    post[0]=collide(f[0],rho,1.0-speed_sq,1.0/3.0);
    post[1]=collide(f[1],rho,axisFactor(uy,true,speed_sq),1.0/18.0);
    post[2]=collide(f[2],rho,axisFactor(uy,false,speed_sq),1.0/18.0);
    post[3]=collide(f[3],rho,axisFactor(ux,true,speed_sq),1.0/18.0);
    post[4]=collide(f[4],rho,axisFactor(ux,false,speed_sq),1.0/18.0);
    post[5]=collide(f[5],rho,axisFactor(uz,true,speed_sq),1.0/18.0);
    post[6]=collide(f[6],rho,axisFactor(uz,false,speed_sq),1.0/18.0);
    var cu=ux+uy; post[7]=collide(f[7],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=-ux+uy; post[8]=collide(f[8],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=ux-uy; post[9]=collide(f[9],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=-ux-uy; post[10]=collide(f[10],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=uy+uz; post[11]=collide(f[11],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=uy-uz; post[12]=collide(f[12],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=-uy+uz; post[13]=collide(f[13],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=-uy-uz; post[14]=collide(f[14],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=ux+uz; post[15]=collide(f[15],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=ux-uz; post[16]=collide(f[16],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=-ux+uz; post[17]=collide(f[17],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
    cu=-ux-uz; post[18]=collide(f[18],rho,diagonalFactor(cu,speed_sq),1.0/36.0);
}
fn quantize(value: f32) i64 {
    const scaled = value * 1_000_000.0;
    const magnitude = @abs(scaled);
    var whole: i64 = @intFromFloat(magnitude);
    if (magnitude - @as(f32, @floatFromInt(whole)) >= 0.5) whole += 1;
    return if (scaled < 0.0) -whole else whole;
}

/// Clean-room Parboil D3Q19 profile; Illinois Open Source License is in package docs.
pub export fn parboil_lbm(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != Q) return -1;
    var nonzero = false;
    for (0..Q) |q| {
        if (input[q] < 0 or input[q] > 100_000) return -1;
        if (input[q] != 0) nonzero = true;
    }
    if (!nonzero) return -1;

    var source = [_]f32{0} ** (CELLS * Q);
    var destination = [_]f32{0} ** (HALO_CELLS * Q);
    for (0..3) |z| {
        for (0..3) |y| {
            for (0..3) |x| {
                const cell = cellIndex(x,y,z);
                for (0..Q) |q| {
                    const weight = initialWeight(q);
                    source[cell*Q+q] = weight;
                    destination[haloIndex(@intCast(x),@intCast(y),@intCast(z),q)] = weight;
                }
            }
        }
    }
    for (0..Q) |q| source[cellIndex(1,1,1)*Q+q] = @as(f32, @floatFromInt(input[q])) / 1_000_000.0;

    for (0..3) |z| {
        for (0..3) |y| {
            for (0..3) |x| {
                const cell = cellIndex(x,y,z);
                const obstacle = x==0 or x==2 or y==0 or y==2 or z==0 or z==2;
                var post = [_]f32{0} ** Q;
                if (!obstacle) collideCell(source[cell*Q..cell*Q+Q], post[0..]);
                for (0..Q) |q| {
                    const outgoing = if (obstacle) source[cell*Q+OPP[q]] else post[q];
                    destination[haloIndex(@as(i32,@intCast(x))+DX[q],@as(i32,@intCast(y))+DY[q],@as(i32,@intCast(z))+DZ[q],q)] = outgoing;
                }
            }
        }
    }

    var checksum: i64 = 0;
    for (0..3) |z| {
        for (0..3) |y| {
            for (0..3) |x| {
                const cell = cellIndex(x,y,z);
                for (0..Q) |q| checksum += @as(i64, @intCast(cell+1)) * quantize(destination[haloIndex(@intCast(x),@intCast(y),@intCast(z),q)]);
            }
        }
    }
    return checksum;
}
