#[no_mangle]
pub unsafe extern "C" fn gravitational_force(v: *const f64, n: usize, output: *mut f64, capacity: usize) -> i64 {
    if v.is_null() || n != 6 { return -1; }
    let values = std::slice::from_raw_parts(v, 6);
    if values.iter().any(|x| !x.is_finite()) { return -1; }
    let (m1,x1,y1,m2,x2,y2) = (values[0],values[1],values[2],values[3],values[4],values[5]);
    if m1.abs()>1.0e12 || m2.abs()>1.0e12 || (m1!=0.0 && m1.abs()<1.0e-12) ||
       (m2!=0.0 && m2.abs()<1.0e-12) || x1.abs()>1.0e6 || y1.abs()>1.0e6 || x2.abs()>1.0e6 || y2.abs()>1.0e6 { return -1; }
    let (dx,dy) = (x1-x2,y1-y2);
    let d2 = dx*dx+dy*dy;
    if d2!=0.0 && d2<1.0e-12 { return -1; }
    if output.is_null() || capacity<2 { return -2; }
    if d2==0.0 { *output=0.0; *output.add(1)=0.0; return 2; }
    let distance=d2.sqrt();
    let magnitude=6.67430e-11*m1*m2/d2;
    *output=magnitude*(dx/distance); *output.add(1)=magnitude*(dy/distance);
    2
}
