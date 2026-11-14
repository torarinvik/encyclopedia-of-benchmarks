use std::collections::BTreeSet;

#[no_mangle]
pub unsafe extern "C" fn closest_pair_sweep(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(5..=130).contains(&length) { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    let raw_n=values[0];
    if !(2..=64).contains(&raw_n) { return -1; }
    let n=raw_n as usize;
    if length!=1+2*n { return -1; }
    let mut points=Vec::with_capacity(n);
    for i in 0..n {
        let (x,y)=(values[1+2*i],values[2+2*i]);
        if !(-1000..=1000).contains(&x) || !(-1000..=1000).contains(&y) { return -1; }
        points.push((x,y));
    }
    points.sort_unstable();
    if points.windows(2).any(|pair| pair[0]==pair[1]) { return 0; }
    let mut active=BTreeSet::new();
    let mut left=0;
    let mut best=8_000_001i64;
    for &(x,y) in &points {
        while left<n && points[left].0<x && (x-points[left].0)*(x-points[left].0)>best {
            active.remove(&(points[left].1,points[left].0));
            left+=1;
        }
        let (mut lo,mut hi)=(0i64,3000i64);
        while lo<hi {
            let middle=(lo+hi+1)/2;
            if middle*middle<=best { lo=middle; } else { hi=middle-1; }
        }
        for &(old_y,old_x) in active.range((y-lo,-1001)..=(y+lo,1001)) {
            let (dx,dy)=(x-old_x,y-old_y);
            best=best.min(dx*dx+dy*dy);
        }
        active.insert((y,x));
    }
    best
}
