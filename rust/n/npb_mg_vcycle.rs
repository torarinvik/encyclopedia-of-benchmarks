#[no_mangle]
pub unsafe extern "C" fn npb_mg_vcycle(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    const SIDE: usize = 4;
    const CELLS: usize = 64;
    if input.is_null() || !(2..=34).contains(&length) { return -1; }
    let iterations_v = *input;
    let count_v = *input.add(1);
    if !iterations_v.is_finite() || iterations_v.fract() != 0.0 || !(1.0..=4.0).contains(&iterations_v)
        || !count_v.is_finite() || count_v.fract() != 0.0 || !(0.0..=8.0).contains(&count_v) { return -1; }
    let iterations = iterations_v as usize;
    let count = count_v as usize;
    if length != 2 + 4 * count { return -1; }
    let mut rhs = [0.0f64; CELLS];
    let mut seen = [false; CELLS];
    for source in 0..count {
        let base = 2 + 4 * source;
        let xv = *input.add(base);
        let yv = *input.add(base + 1);
        let zv = *input.add(base + 2);
        let value = *input.add(base + 3);
        if !xv.is_finite() || xv.fract() != 0.0 || !(0.0..4.0).contains(&xv)
            || !yv.is_finite() || yv.fract() != 0.0 || !(0.0..4.0).contains(&yv)
            || !zv.is_finite() || zv.fract() != 0.0 || !(0.0..4.0).contains(&zv)
            || !value.is_finite() || !(-4.0..=4.0).contains(&value) { return -1; }
        let q = xv as usize + SIDE * (yv as usize + SIDE * zv as usize);
        if seen[q] { return -1; }
        seen[q] = true;
        rhs[q] = value;
    }
    if output.is_null() || capacity < 1 { return -2; }

    fn wrap(v: isize, n: usize) -> usize {
        if v < 0 { (v + n as isize) as usize } else if v >= n as isize { (v - n as isize) as usize } else { v as usize }
    }
    fn idx(x: usize, y: usize, z: usize, n: usize) -> usize { x + n * (y + n * z) }
    fn stencil(src: &[f64], dst: &mut [f64], n: usize, center: f64, face: f64, edge: f64, corner: f64) {
        for z in 0..n { for y in 0..n { for x in 0..n {
            let q = idx(x, y, z, n);
            let mut total = center * src[q];
            for dz in -1isize..=1 { for dy in -1isize..=1 { for dx in -1isize..=1 {
                let distance = dx.abs() + dy.abs() + dz.abs();
                if distance == 0 { continue; }
                let weight = if distance == 1 { face } else if distance == 2 { edge } else { corner };
                let neighbor = idx(wrap(x as isize + dx, n), wrap(y as isize + dy, n), wrap(z as isize + dz, n), n);
                total += weight * src[neighbor];
            } } }
            dst[q] = total;
        } } }
    }
    fn restrict(fine: &[f64], n: usize, coarse: &mut [f64]) {
        let h = n / 2;
        for z in 0..h { for y in 0..h { for x in 0..h {
            let mut total = 0.0;
            for dz in -1isize..=1 { for dy in -1isize..=1 { for dx in -1isize..=1 {
                let wx = if dx == 0 { 1.0 } else { 0.5 };
                let wy = if dy == 0 { 1.0 } else { 0.5 };
                let wz = if dz == 0 { 1.0 } else { 0.5 };
                let q = idx(wrap((2*x) as isize + dx, n), wrap((2*y) as isize + dy, n), wrap((2*z) as isize + dz, n), n);
                total += wx * wy * wz * fine[q];
            } } }
            coarse[idx(x, y, z, h)] = 0.5 * total;
        } } }
    }
    fn interpolate(coarse: &[f64], h: usize, fine: &mut [f64]) {
        let n = 2*h;
        for z in 0..n { for y in 0..n { for x in 0..n {
            let (bx, by, bz) = (x/2, y/2, z/2);
            let (nx, ny, nz) = (if x%2 == 1 {2} else {1}, if y%2 == 1 {2} else {1}, if z%2 == 1 {2} else {1});
            let (wx, wy, wz) = (if x%2 == 1 {0.5} else {1.0}, if y%2 == 1 {0.5} else {1.0}, if z%2 == 1 {0.5} else {1.0});
            let mut total = 0.0;
            for iz in 0..nz { for iy in 0..ny { for ix in 0..nx {
                total += wx*wy*wz*coarse[idx((bx+ix)%h, (by+iy)%h, (bz+iz)%h, h)];
            } } }
            fine[idx(x,y,z,n)] = total;
        } } }
    }
    fn vcycle(rhs: &[f64], n: usize, solution: &mut [f64]) {
        if n == 2 { stencil(rhs, solution, n, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0); return; }
        let h = n/2;
        let mut cr = [0.0; CELLS]; let mut cs = [0.0; CELLS]; let mut prolonged = [0.0; CELLS];
        let mut applied = [0.0; CELLS]; let mut remaining = [0.0; CELLS]; let mut post = [0.0; CELLS];
        restrict(rhs, n, &mut cr[..h*h*h]);
        vcycle(&cr[..h*h*h], h, &mut cs[..h*h*h]);
        interpolate(&cs[..h*h*h], h, &mut prolonged[..n*n*n]);
        stencil(&prolonged[..n*n*n], &mut applied[..n*n*n], n, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0);
        for q in 0..n*n*n { remaining[q] = rhs[q] - applied[q]; }
        stencil(&remaining[..n*n*n], &mut post[..n*n*n], n, -3.0/8.0, 1.0/32.0, -1.0/64.0, 0.0);
        for q in 0..n*n*n { solution[q] = prolonged[q] + post[q]; }
    }

    let mut solution = [0.0f64; CELLS];
    let mut applied = [0.0f64; CELLS];
    let mut residual = [0.0f64; CELLS];
    let mut correction = [0.0f64; CELLS];
    for _ in 0..iterations {
        stencil(&solution, &mut applied, SIDE, -8.0/3.0, 0.0, 1.0/6.0, 1.0/12.0);
        for q in 0..CELLS { residual[q] = rhs[q] - applied[q]; }
        vcycle(&residual, SIDE, &mut correction);
        for q in 0..CELLS { solution[q] += correction[q]; }
    }
    let checksum: f64 = solution.iter().sum();
    *output = checksum;
    1
}
