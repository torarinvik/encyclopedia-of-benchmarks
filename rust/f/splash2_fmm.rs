const MAX_PARTICLES: usize = 48;
const BOXES: usize = 16;
const ORDER: usize = 32;
const STRIDE: usize = ORDER + 1;

#[no_mangle]
pub unsafe extern "C" fn splash2_fmm(input: *const f64, input_length: usize,
                                        output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || !(7..=145).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let requested = values[0];
    if !(2.0..=48.0).contains(&requested) || requested.fract() != 0.0 { return -1; }
    let count = requested as usize;
    if input_length != 1 + 3 * count { return -1; }
    let mut x = [0.0; MAX_PARTICLES];
    let mut y = [0.0; MAX_PARTICLES];
    let mut charge = [0.0; MAX_PARTICLES];
    let mut box_id = [0usize; MAX_PARTICLES];
    for i in 0..count {
        let px = values[1 + 3 * i];
        let py = values[2 + 3 * i];
        let q = values[3 + 3 * i];
        if !(0.0..8.0).contains(&px) || px.fract() != 0.0 ||
           !(0.0..8.0).contains(&py) || py.fract() != 0.0 ||
           !(-3.0..=3.0).contains(&q) || q.fract() != 0.0 { return -1; }
        x[i] = px; y[i] = py; charge[i] = q;
        box_id[i] = (py as usize / 2) * 4 + px as usize / 2;
        for j in 0..i { if x[i] == x[j] && y[i] == y[j] { return -1; } }
    }
    if output.is_null() || output_capacity < count { return -2; }
    let mut mr = [[0.0; STRIDE]; BOXES];
    let mut mi = [[0.0; STRIDE]; BOXES];
    let mut lr = [[0.0; STRIDE]; BOXES];
    let mut li = [[0.0; STRIDE]; BOXES];
    for i in 0..count {
        let b = box_id[i];
        let zr = x[i] - (2 * (b % 4) + 1) as f64;
        let zi = y[i] - (2 * (b / 4) + 1) as f64;
        let (mut pr, mut pi) = (1.0, 0.0);
        mr[b][0] += charge[i];
        for k in 1..=ORDER {
            let (nr, ni) = (pr * zr - pi * zi, pr * zi + pi * zr);
            pr = nr; pi = ni;
            mr[b][k] += charge[i] * pr;
            mi[b][k] += charge[i] * pi;
        }
    }
    for target in 0..BOXES {
        let (tx, ty) = ((target % 4) as i32, (target / 4) as i32);
        for source in 0..BOXES {
            let (sx, sy) = ((source % 4) as i32, (source / 4) as i32);
            let (dbx, dby) = (tx - sx, ty - sy);
            if dbx.abs() <= 1 && dby.abs() <= 1 { continue; }
            let (dx, dy) = (2.0 * dbx as f64, 2.0 * dby as f64);
            let r2 = dx * dx + dy * dy;
            let mut ir = [0.0; 2 * ORDER + 1];
            let mut ii = [0.0; 2 * ORDER + 1];
            ir[0] = 1.0;
            let (odr, odi) = (dx / r2, -dy / r2);
            for p in 1..=2 * ORDER {
                ir[p] = ir[p - 1] * odr - ii[p - 1] * odi;
                ii[p] = ir[p - 1] * odi + ii[p - 1] * odr;
            }
            let mut constant = mr[source][0] * 0.5 * r2.ln();
            for k in 1..=ORDER {
                constant -= (mr[source][k] * ir[k] - mi[source][k] * ii[k]) / k as f64;
            }
            lr[target][0] += constant;
            for n in 1..=ORDER {
                let (mut sr, mut si) = (0.0, 0.0);
                for k in 1..=ORDER {
                    let mut choose = 1.0;
                    for j in 1..=n { choose *= (k + j - 1) as f64 / j as f64; }
                    let scale = choose / k as f64;
                    let p = k + n;
                    sr += scale * (mr[source][k] * ir[p] - mi[source][k] * ii[p]);
                    si += scale * (mr[source][k] * ii[p] + mi[source][k] * ir[p]);
                }
                let qscale = (if n % 2 == 1 { 1.0 } else { -1.0 }) / n as f64;
                let mscale = if n % 2 == 1 { -1.0 } else { 1.0 };
                lr[target][n] += mr[source][0] * qscale * ir[n] - mscale * sr;
                li[target][n] += mr[source][0] * qscale * ii[n] - mscale * si;
            }
        }
    }
    for i in 0..count {
        let b = box_id[i];
        let wr = x[i] - (2 * (b % 4) + 1) as f64;
        let wi = y[i] - (2 * (b / 4) + 1) as f64;
        let (mut pr, mut pi) = (1.0, 0.0);
        let mut value = lr[b][0];
        for n in 1..=ORDER {
            let (nr, ni) = (pr * wr - pi * wi, pr * wi + pi * wr);
            pr = nr; pi = ni;
            value += lr[b][n] * pr - li[b][n] * pi;
        }
        for j in 0..count {
            if j == i { continue; }
            let sx = (box_id[j] % 4) as i32;
            let sy = (box_id[j] / 4) as i32;
            if ((b % 4) as i32 - sx).abs() > 1 || ((b / 4) as i32 - sy).abs() > 1 { continue; }
            let dx = x[j] - x[i];
            let dy = y[j] - y[i];
            value += charge[j] * 0.5 * (dx * dx + dy * dy).ln();
        }
        unsafe { *output.add(i) = value; }
    }
    count as i64
}
