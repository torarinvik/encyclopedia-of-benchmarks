const MAX_POINTS: usize = 12;

#[inline(never)]
fn py_distance(p: &[f64; 24], a: usize, b: usize, k: usize) -> f64 {
    let ax=p[2*a]; let ay=p[2*a+1];
    let dx=p[2*b]-ax; let dy=p[2*b+1]-ay;
    let px=p[2*k]; let py=p[2*k+1];
    let l2=dx*dx+dy*dy;
    let mut t=((px-ax)*dx+(py-ay)*dy)/l2;
    if t<0.0 { t=0.0; } else if t>1.0 { t=1.0; }
    let nx=ax+t*dx; let ny=ay+t*dy;
    (px-nx).hypot(py-ny)
}

#[inline(never)]
fn rust_distance(p: &[f64; 24], a: usize, b: usize, k: usize, line_len: f64) -> f64 {
    let ax=p[2*a]; let ay=p[2*a+1]; let bx=p[2*b]; let by=p[2*b+1];
    let dx=bx-ax; let dy=by-ay; let px=p[2*k]; let py=p[2*k+1];
    let numerator=(((dy*px)-(dx*py))+(bx*ay))-(by*ax);
    numerator.abs()/line_len
}

fn valid_geometry(p: &[f64; 24], n: usize, epsilon: f64) -> bool {
    if n<3 { return true; }
    for i in 0..n { for j in 0..i {
        if p[2*i]==p[2*j] && p[2*i+1]==p[2*j+1] { return false; }
    }}
    for i in 0..n-2 { for j in i+2..n {
        let ax=p[2*i]; let ay=p[2*i+1];
        let dx=p[2*j]-ax; let dy=p[2*j+1]-ay;
        let l2=dx*dx+dy*dy;
        if !l2.is_finite() || l2<=0.0 { return false; }
        let ll=l2.sqrt();
        if !ll.is_finite() || ll<=0.0 { return false; }
        let mut mp=0.0; let mut mr=0.0; let mut ip=i; let mut ir=i;
        for k in i+1..j {
            let px=p[2*k]; let py=p[2*k+1];
            let t=((px-ax)*dx+(py-ay)*dy)/l2;
            if !(t>=0.0 && t<=1.0) { return false; }
            let dp=py_distance(p,i,j,k); let dr=rust_distance(p,i,j,k,ll);
            if !dp.is_finite() || !dr.is_finite() { return false; }
            if dp>mp { mp=dp; ip=k; }
            if dr>mr { mr=dr; ir=k; }
        }
        if ip!=ir || ((mp>epsilon)!=(mr>epsilon)) { return false; }
    }}
    true
}

fn simplify(p: &[f64; 24], a: usize, b: usize, epsilon: f64, keep: &mut [bool; 12]) {
    if b<=a+1 { return; }
    let mut best=0.0; let mut index=a;
    for k in a+1..b {
        let d=py_distance(p,a,b,k);
        if d>best { best=d; index=k; }
    }
    if best>epsilon {
        keep[index]=true;
        simplify(p,a,index,epsilon,keep);
        simplify(p,index,b,epsilon,keep);
    }
}

#[no_mangle]
pub unsafe extern "C" fn ramer_douglas_peucker(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=26).contains(&input_length) { return -1; }
    let values=unsafe { std::slice::from_raw_parts(input,input_length) };
    if values.iter().any(|x| !x.is_finite()) { return -1; }
    let cv=values[0];
    if cv<0.0 || cv>MAX_POINTS as f64 || cv.fract()!=0.0 { return -1; }
    let n=cv as usize;
    if input_length!=2+2*n || values[1]<0.0 || values[1]>100.0 { return -1; }
    let mut points=[0.0f64;24];
    for i in 0..2*n {
        let x=values[2+i]; if !(-100.0..=100.0).contains(&x) { return -1; }
        points[i]=x;
    }
    if !valid_geometry(&points,n,values[1]) { return -1; }
    let mut keep=[false;12];
    if n>0 { keep[0]=true; }
    if n>1 { keep[n-1]=true; }
    if n>2 { simplify(&points,0,n-1,values[1],&mut keep); }
    let mut staged=[0.0f64;25]; let mut outn=0usize;
    for i in 0..n { if keep[i] {
        staged[1+2*outn]=points[2*i]; staged[2+2*outn]=points[2*i+1]; outn+=1;
    }}
    staged[0]=outn as f64; let length=1+2*outn;
    if output.is_null() || output_capacity<length { return -2; }
    for i in 0..length { unsafe { *output.add(i)=staged[i]; } }
    length as i64
}
