// Clean-room bounded GARDENIA SymGS profile.
#[no_mangle]
pub unsafe extern "C" fn gardenia_symgs(a:*const f64,len:usize,out:*mut f64,cap:usize)->i64{
    const N:usize=8;const M:usize=64;const IMAX:usize=173;
    if a.is_null()||len<3||len>IMAX{return -1;}for q in 0..len{if !(*a.add(q)).is_finite(){return -1;}}
    let nd=*a;let md=*a.add(1);let cd=*a.add(2);if nd.fract()!=0.0||md.fract()!=0.0||cd.fract()!=0.0||nd<1.0||nd>N as f64||md<1.0||md>M as f64||cd<1.0||cd>nd{return -1;}
    let n=nd as usize;let m=md as usize;let c=cd as usize;if len!=5+4*n+c+2*m{return -1;}
    let oa=3;let fa=oa+n;let ra=fa+c+1;let ca=ra+n+1;let va=ca+m;let xa=va+m;let ba=xa+n;
    let mut order=[0usize;N];let mut offsets=[0usize;N+1];let mut rows=[0usize;N+1];let mut cols=[0usize;M];let mut group=[0usize;N];let mut mat=[0.0;M];let mut x=[0.0;N];let mut rhs=[0.0;N];let mut staged=[0.0;N];let mut seen=[false;N];
    for i in 0..n{let z=*a.add(oa+i);if z.fract()!=0.0||z<0.0||z>=nd||seen[z as usize]{return -1;}order[i]=z as usize;seen[order[i]]=true;}
    for k in 0..=c{let z=*a.add(fa+k);if z.fract()!=0.0||z<0.0||z>nd{return -1;}offsets[k]=z as usize;}if offsets[0]!=0||offsets[c]!=n{return -1;}
    for k in 0..c{if offsets[k]>=offsets[k+1]{return -1;}for p in offsets[k]..offsets[k+1]{group[order[p]]=k;}}
    for i in 0..=n{let z=*a.add(ra+i);if z.fract()!=0.0||z<0.0||z>md{return -1;}rows[i]=z as usize;if i>0&&rows[i]<rows[i-1]{return -1;}}if rows[0]!=0||rows[n]!=m{return -1;}
    for u in 0..n{let mut diag=0;let mut d=0.0;let mut offsum=0.0;let mut prev=0;for e in rows[u]..rows[u+1]{let z=*a.add(ca+e);if z.fract()!=0.0||z<0.0||z>=nd{return -1;}cols[e]=z as usize;if e>rows[u]&&cols[e]<=prev{return -1;}prev=cols[e];mat[e]=*a.add(va+e);if mat[e]<-4.0||mat[e]>4.0{return -1;}if cols[e]==u{diag+=1;d=mat[e];}else{if group[u]==group[cols[e]]{return -1;}offsum+=mat[e].abs();}}
        if diag!=1||d<=offsum{return -1;}for e in rows[u]..rows[u+1]{let v=cols[e];let mut found=false;for f in rows[v]..rows[v+1]{if cols[f]==u{if mat[f]!=mat[e]{return -1;}found=true;break;}}if !found{return -1;}}
    }
    for i in 0..n{x[i]=*a.add(xa+i);rhs[i]=*a.add(ba+i);if x[i]<-4.0||x[i]>4.0||rhs[i]<-4.0||rhs[i]>4.0{return -1;}}
    if out.is_null()||cap<n{return -2;}
    for pass in 0..2{for step in 0..c{let k=if pass==0{step}else{c-1-step};for p in offsets[k]..offsets[k+1]{let u=order[p];let mut sum=0.0;let mut d=0.0;for e in rows[u]..rows[u+1]{let v=cols[e];if v==u{d=mat[e];}else{sum+=x[v]*mat[e];}}if d!=0.0{x[u]=(rhs[u]-sum)/d;}}}}
    staged[..n].copy_from_slice(&x[..n]);std::ptr::copy_nonoverlapping(staged.as_ptr(),out,n);n as i64
}
