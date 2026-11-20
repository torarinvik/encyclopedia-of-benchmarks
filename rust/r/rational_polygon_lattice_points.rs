fn rpl_floor_div(a: i64, b: i64) -> i64 { a.div_euclid(b) }
fn rpl_ceil_div(a: i64, b: i64) -> i64 { -rpl_floor_div(-a, b) }

fn rpl_floor_sum(n0: i64, m0: i64, a0: i64, b0: i64) -> i64 {
    let aq = rpl_floor_div(a0, m0);
    let bq = rpl_floor_div(b0, m0);
    let mut answer = aq*n0*(n0-1)/2+bq*n0;
    let mut a = a0-aq*m0;
    let mut b = b0-bq*m0;
    let mut n = n0;
    let mut m = m0;
    loop {
        if a >= m { answer += (n-1)*n*(a/m)/2; a %= m; }
        if b >= m { answer += n*(b/m); b %= m; }
        let top = a*n+b;
        if top < m { return answer; }
        n = top/m;
        b = top%m;
        std::mem::swap(&mut m, &mut a);
    }
}

fn rpl_edge_chunk(scale: i64, ax: i64, ay: i64, dx: i64, dy: i64,
                  start: i64, columns: i64) -> i64 {
    if columns <= 0 { return 0; }
    let mut aa=dy*scale;
    let mut bb=ay*dx-dy*ax;
    let mut den=scale*dx;
    if den<0 { aa=-aa; bb=-bb; den=-den; }
    let base=aa*start+bb;
    if dx>0 { return -rpl_floor_sum(columns,den,aa,base); }
    -rpl_floor_sum(columns,den,-aa,-base)-columns
}

fn rpl_inside(xs: &[i64;8], ys: &[i64;8], n: usize,
              scale: i64, x: i64, y: i64) -> bool {
    let px=x*scale;
    let py=y*scale;
    let mut inside=false;
    for i in 0..n {
        let j=(i+1)%n;
        let cross=(xs[j]-xs[i])*(py-ys[i])-(ys[j]-ys[i])*(px-xs[i]);
        if cross==0 && px>=xs[i].min(xs[j]) && px<=xs[i].max(xs[j]) && py>=ys[i].min(ys[j]) && py<=ys[i].max(ys[j]) { return false; }
        if (ys[i]>py)!=(ys[j]>py) {
            let dy=ys[j]-ys[i];
            let dx=xs[j]-xs[i];
            let left=xs[i]*dy+(py-ys[i])*dx;
            let right=px*dy;
            if (dy>0 && left>right) || (dy<0 && left<right) { inside=!inside; }
        }
    }
    inside
}

#[no_mangle]
pub unsafe extern "C" fn rational_polygon_lattice_points(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 19 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let scale = values[0];
    let nr = values[1];
    if !(2..=8).contains(&scale) || !(3..=8).contains(&nr)
        || length != (2+2*nr) as usize { return -1; }
    let n = nr as usize;
    let mut xs = [0_i64; 8];
    let mut ys = [0_i64; 8];
    let mut fractional = false;
    for i in 0..n {
        xs[i] = values[2+2*i];
        ys[i] = values[3+2*i];
        if !(-32..=32).contains(&xs[i]) || !(-32..=32).contains(&ys[i]) { return -1; }
        if xs[i] < -4*scale || xs[i] > 4*scale || ys[i] < -4*scale || ys[i] > 4*scale { return -1; }
        fractional |= xs[i]%scale != 0 || ys[i]%scale != 0;
        for j in 0..i { if xs[i] == xs[j] && ys[i] == ys[j] { return -1; } }
    }
    if !fractional { return -1; }
    let mut area2 = 0_i64;
    for i in 0..n {
        let j = (i+1)%n;
        area2 += xs[i]*ys[j]-ys[i]*xs[j];
    }
    if area2 == 0 { return -1; }
    let orientation = if area2 > 0 { 1_i64 } else { -1_i64 };
    for i in 0..n {
        let next = (i+1)%n;
        for j in 0..n {
            if j == i || j == next { continue; }
            let cross = (xs[next]-xs[i])*(ys[j]-ys[i])-(ys[next]-ys[i])*(xs[j]-xs[i]);
            if cross*orientation <= 0 { return -1; }
        }
    }
    let mut signed_count = 0_i64;
    for i in 0..n {
        let j = (i+1)%n;
        let dx = xs[j]-xs[i];
        let dy = ys[j]-ys[i];
        if dx == 0 { continue; }
        let lo = xs[i].min(xs[j]);
        let hi = xs[i].max(xs[j]);
        let start = rpl_ceil_div(lo,scale);
        let stop = rpl_ceil_div(hi,scale);
        let mut cursor = start;
        for col in start..stop {
            let mut event=false;
            for k in 0..n { if xs[k]==col*scale { event=true; } }
            if event {
                signed_count += rpl_edge_chunk(scale,xs[i],ys[i],dx,dy,cursor,col-cursor);
                cursor=col+1;
            }
        }
        signed_count += rpl_edge_chunk(scale,xs[i],ys[i],dx,dy,cursor,stop-cursor);
    }
    for i in 0..n {
        if xs[i]%scale!=0 { continue; }
        let mut first=true;
        for j in 0..i { if xs[j]==xs[i] { first=false; } }
        if !first { continue; }
        let x=xs[i]/scale;
        let mut count=0_i64;
        for y in -4_i64..=4_i64 { if rpl_inside(&xs,&ys,n,scale,x,y) { count+=1; } }
        signed_count += orientation*count;
    }
    let result = signed_count*orientation;
    if result >= 0 { result } else { -1 }
}
