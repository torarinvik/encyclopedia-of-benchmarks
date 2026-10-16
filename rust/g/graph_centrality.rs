fn put(o:&mut [u8],a:usize,v:i64){o[a*8..a*8+8].copy_from_slice(&v.to_le_bytes());}
#[no_mangle] pub extern "C" fn graph_centrality(input:*const i64,len:usize,output:*mut u8,cap:usize)->i64{
 if input.is_null()||len<2{return -1} let x=unsafe{std::slice::from_raw_parts(input,len)};let(nn,ee)=(x[0],x[1]);if nn<1||nn>16||ee<0||ee>nn*(nn-1)||len!=2+3*ee as usize{return -1}let(n,e)=(nn as usize,ee as usize);let inf=i64::MAX;let mut d=[[i64::MAX;16];16];for i in 0..n{d[i][i]=0;}
 for z in 0..e{let(a,b,w)=(x[2+3*z],x[3+3*z],x[4+3*z]);if a<0||a>=nn||b<0||b>=nn||a==b||w<1||w>1_000_000||d[a as usize][b as usize]!=inf{return -1}d[a as usize][b as usize]=w;}
 for k in 0..n{for i in 0..n{if d[i][k]==inf{continue}for j in 0..n{if d[k][j]!=inf&&d[i][k]+d[k][j]<d[i][j]{d[i][j]=d[i][k]+d[k][j];}}}}
 let(mut c,mut m,mut be,mut bh)=(-1i64,-1i64,inf,f64::NEG_INFINITY);if n==1{c=0;m=0}else{for i in 0..n{let(mut r,mut ec,mut h)=(0,0i64,0.0);for j in 0..n{if i!=j&&d[i][j]!=inf{r+=1;ec=ec.max(d[i][j]);h+=1.0/d[i][j] as f64;}}if r>0&&ec<be{be=ec;c=i as i64;}if r>0&&h>bh{bh=h;m=i as i64;}}}
 if output.is_null()||cap<16{return -2}let o=unsafe{std::slice::from_raw_parts_mut(output,16)};put(o,0,c);put(o,1,m);16
}
