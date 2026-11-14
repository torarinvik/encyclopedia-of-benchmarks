fn projection(points: &[(i64,i64)], index: usize, dx: i64, dy: i64, axis: usize) -> i64 {
    let (x,y)=points[index];
    if axis==2 { dx*y-dy*x } else { dx*x+dy*y }
}
fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b!=0 { let remainder=a%b; a=b; b=remainder; }
    a
}

#[no_mangle]
pub unsafe extern "C" fn minimum_area_enclosing_rectangle(input: *const i64, length: usize,
                                                            output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(7..=34).contains(&length) { return -1; }
    let values=std::slice::from_raw_parts(input,length);
    if !(3..=16).contains(&values[0]) { return -1; }
    let n=values[0] as usize;
    if length!=1+2*n || values[1..].iter().any(|&x| !(-100..=100).contains(&x)) { return -1; }
    let points: Vec<(i64,i64)>=values[1..].chunks_exact(2).map(|p|(p[0],p[1])).collect();
    for i in 0..n {
        let next=(i+1)%n;
        let (ax,ay)=points[i];
        let (dx,dy)=(points[next].0-ax,points[next].1-ay);
        for j in 0..n {
            if j!=i && j!=next && dx*(points[j].1-ay)-dy*(points[j].0-ax)<=0 { return -1; }
        }
    }
    let (first_dx,first_dy)=(points[1].0-points[0].0,points[1].1-points[0].1);
    let mut supports=[0usize;3];
    for i in 1..n {
        for axis in 0..3 {
            let current=projection(&points,supports[axis],first_dx,first_dy,axis);
            let candidate=projection(&points,i,first_dx,first_dy,axis);
            if (axis==1 && candidate<current) || (axis!=1 && candidate>current) { supports[axis]=i; }
        }
    }
    let (mut best_num,mut best_den)=(0i64,1i64);
    for i in 0..n {
        let (ax,ay)=points[i];
        let (dx,dy)=(points[(i+1)%n].0-ax,points[(i+1)%n].1-ay);
        for axis in 0..3 {
            for _ in 0..n {
                let next=(supports[axis]+1)%n;
                let current=projection(&points,supports[axis],dx,dy,axis);
                let candidate=projection(&points,next,dx,dy,axis);
                if (axis==1 && candidate<=current) || (axis!=1 && candidate>=current) { supports[axis]=next; }
                else { break; }
            }
        }
        let span=projection(&points,supports[0],dx,dy,0)-projection(&points,supports[1],dx,dy,1);
        let thickness=projection(&points,supports[2],dx,dy,2)-(dx*ay-dy*ax);
        let (numerator,denominator)=(span*thickness,dx*dx+dy*dy);
        if i==0 || numerator*best_den<best_num*denominator { best_num=numerator; best_den=denominator; }
    }
    let divisor=gcd(best_num,best_den);
    if output.is_null() || capacity<16 { return -2; }
    let mut result=[0u8;16];
    result[..8].copy_from_slice(&(best_num/divisor).to_le_bytes());
    result[8..].copy_from_slice(&(best_den/divisor).to_le_bytes());
    std::ptr::copy_nonoverlapping(result.as_ptr(),output,16);
    16
}
