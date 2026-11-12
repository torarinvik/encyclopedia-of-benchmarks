#[no_mangle]
pub unsafe extern "C" fn graphai_ggnn_message_update(
    input: *const f64, length: usize, output: *mut f64, capacity: usize,
) -> i64 {
    const N: usize = 8; const M: usize = 24; const D: usize = 4;
    if input.is_null() || length < 3 || length > 453 { return -1; }
    for q in 0..length { if !(*input.add(q)).is_finite() { return -1; } }
    let (nv,mv,dv)=(*input,*input.add(1),*input.add(2));
    if nv.fract()!=0.0 || mv.fract()!=0.0 || dv.fract()!=0.0 ||
        nv<1.0 || nv>N as f64 || mv<0.0 || mv>M as f64 || dv<1.0 || dv>D as f64 { return -1; }
    let (n,m,d)=(nv as usize,mv as usize,dv as usize);
    if length!=4+n+m+n*d+6*n*n { return -1; }
    let row_at=3; let col_at=row_at+n+1; let h_at=col_at+m;
    let wz_at=h_at+n*d; let wr_at=wz_at+n*n; let wc_at=wr_at+n*n;
    let uz_at=wc_at+n*n; let ur_at=uz_at+n*n; let uc_at=ur_at+n*n;
    if *input.add(row_at)!=0.0 || *input.add(col_at-1)!=m as f64 { return -1; }
    let mut row=[0usize;N+1]; let mut col=[0usize;M];
    for i in 0..=n { let x=*input.add(row_at+i); if x.fract()!=0.0 || x<0.0 || x>m as f64 {return -1;} row[i]=x as usize; if i>0 && row[i]<row[i-1] {return -1;} }
    for e in 0..m { let x=*input.add(col_at+e); if x.fract()!=0.0 || x<0.0 || x>=n as f64 {return -1;} col[e]=x as usize; }
    for q in h_at..wz_at { let x=*input.add(q); if !(-1.0..=1.0).contains(&x) {return -1;} }
    for q in wz_at..length { let x=*input.add(q); if !(-0.25..=0.25).contains(&x) {return -1;} }
    let required=n*d; if output.is_null() || capacity<required {return -2;}
    let mut agg=[0.0;N*D]; let mut z=[0.0;N*D]; let mut r=[0.0;N*D];
    let mut can=[0.0;N*D]; let mut staged=[0.0;N*D];
    for v in 0..n { for e in row[v]..row[v+1] { for f in 0..d { agg[v*d+f]+=*input.add(h_at+col[e]*d+f); } } }
    for v in 0..n { for f in 0..d {
        let (mut wz,mut wr,mut uz,mut ur)=(0.0,0.0,0.0,0.0);
        for k in 0..n { let a=v*n+k; let b=k*d+f;
            wz+=*input.add(wz_at+a)*agg[b]; wr+=*input.add(wr_at+a)*agg[b];
            uz+=*input.add(uz_at+a)* *input.add(h_at+b); ur+=*input.add(ur_at+a)* *input.add(h_at+b);
        }
        let at=v*d+f; z[at]=1.0/(1.0+(-(wz+uz)).exp()); r[at]=1.0/(1.0+(-(wr+ur)).exp());
    } }
    for v in 0..n { for f in 0..d {
        let (mut graph,mut state)=(0.0,0.0);
        for k in 0..n { let a=v*n+k; let b=k*d+f;
            graph+=*input.add(wc_at+a)*agg[b]; state+=*input.add(uc_at+a)*(r[b]* *input.add(h_at+b));
        }
        let at=v*d+f; can[at]=(graph+state).tanh();
        staged[at]=(1.0-z[at])* *input.add(h_at+at)+z[at]*can[at];
    } }
    for q in 0..required { *output.add(q)=staged[q]; }
    required as i64
}
