const MAX_N:usize=256;const MAX_Q:usize=1024;const LEVELS:usize=9;
unsafe fn put(out:*mut u8,slot:usize,value:i64){let bits=value as u64;for i in 0..8{*out.add(slot*8+i)=(bits>>(8*i)) as u8;}}
#[no_mangle]
pub unsafe extern "C" fn binary_lifting_kth_ancestor(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<4{return -1;}let a=std::slice::from_raw_parts(input,length);if a[0]<1||a[0]>MAX_N as i64{return -1;}let n=a[0] as usize;if a[1]<0||a[1]>=n as i64||a[2]!=(n-1) as i64||a[3]<0||a[3]>MAX_Q as i64{return -1;}let m=a[2] as usize;let q=a[3] as usize;let qo=4+2*m;if length!=qo+2*q{return -1;}let root=a[1] as usize;
 let mut adj=[[false;MAX_N];MAX_N];for e in 0..m{let x=a[4+2*e];let y=a[5+2*e];if x<0||y<0||x>=n as i64||y>=n as i64||x==y{return -1;}adj[x as usize][y as usize]=true;adj[y as usize][x as usize]=true;}
 for i in 0..q{let v=a[qo+2*i];let k=a[qo+2*i+1];if v<0||v>=n as i64||k<0{return -1;}}
 let mut up=[[0usize;MAX_N];LEVELS];let mut parent=[-1i64;MAX_N];let mut stack=[0usize;MAX_N];let mut top=0;let mut reached=0;parent[root]=root as i64;up[0][root]=root;stack[top]=root;top+=1;
 while top>0{top-=1;let u=stack[top];reached+=1;for v in 0..n{if adj[u][v]{if v as i64==parent[u]{continue;}if parent[v]!=-1{return -1;}parent[v]=u as i64;up[0][v]=u;stack[top]=v;top+=1;}}}if reached!=n{return -1;}
 for l in 1..LEVELS{for v in 0..n{up[l][v]=up[l-1][up[l-1][v]];}}
 let bytes=(1+q)*8;if output.is_null()||capacity<bytes{return -2;}put(output,0,q as i64);for i in 0..q{let mut v=a[qo+2*i] as usize;let k=a[qo+2*i+1] as u64;if k>=n as u64{v=root;}else{for bit in 0..LEVELS{if k&(1u64<<bit)!=0{v=up[bit][v];}}}put(output,1+i,v as i64);}bytes as i64
}
