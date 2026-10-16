/// Bounded ordered adjacency-list graph operation trace.
fn put(out: &mut [u8], i: usize, v: i64) { out[i*8..i*8+8].copy_from_slice(&v.to_le_bytes()); }
fn findv(order: &[usize;32], n:usize, v:usize)->Option<usize>{(0..n).find(|&i|order[i]==v)}
fn findn(rows:&[[usize;34];32],deg:&[usize;32],u:usize,v:usize)->Option<usize>{(0..deg[u]).find(|&i|rows[u][i]==v)}
fn deln(rows:&mut [[usize;34];32],deg:&mut [usize;32],u:usize,at:usize){for i in at..deg[u]-1{rows[u][i]=rows[u][i+1];}deg[u]-=1;}
#[no_mangle]
pub extern "C" fn graph_adjacency_list(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<4{return -1} let v=unsafe{std::slice::from_raw_parts(input,length)};let d=v[0];let nn=v[1];if !(d==0||d==1)||nn<0||nn>32||length<4+nn as usize{return -1}
 let mut order=[0usize;32];let mut rows=[[0usize;34];32];let mut deg=[0usize;32];let mut n=nn as usize;let mut k=2;
 for i in 0..n{let x=v[k];k+=1;if !(0..32).contains(&x)||findv(&order,i,x as usize).is_some(){return -1}order[i]=x as usize;}
 let ec=v[k];k+=1;if ec<0||ec>1024||length<k+2*ec as usize+1{return -1}for _ in 0..ec{let aa=v[k];let bb=v[k+1];k+=2;if !(0..32).contains(&aa)||!(0..32).contains(&bb){return -1}let(a,b)=(aa as usize,bb as usize);if findv(&order,n,a).is_none()||findv(&order,n,b).is_none()||findn(&rows,&deg,a,b).is_some(){return -1}rows[a][deg[a]]=b;deg[a]+=1;if d==0{rows[b][deg[b]]=a;deg[b]+=1;}}
 let oo=v[k];k+=1;if oo<0||oo>64||length!=k+3*oo as usize{return -1}let ops=oo as usize;let mut res=[0i64;64];
 for z in 0..ops{let op=v[k];let aa=v[k+1];let bb=v[k+2];k+=3;match op{
 0=>{if !(0..32).contains(&aa)||bb!=0||n>=32||findv(&order,n,aa as usize).is_some(){return -1}order[n]=aa as usize;deg[aa as usize]=0;n+=1;res[z]=1;},
 1=>{if !(0..32).contains(&aa)||bb!=0{return -1}let u=aa as usize;let Some(at)=findv(&order,n,u)else{return -1};if d==1{for j in 0..n{let q=order[j];while let Some(x)=findn(&rows,&deg,q,u){deln(&mut rows,&mut deg,q,x);}}}else{while deg[u]>0{let b=rows[u][deg[u]-1];deg[u]-=1;if b!=u{if let Some(x)=findn(&rows,&deg,b,u){deln(&mut rows,&mut deg,b,x);}}}}for j in at..n-1{order[j]=order[j+1];}n-=1;deg[u]=0;res[z]=1;},
 2|3|5=>{if !(0..32).contains(&aa)||!(0..32).contains(&bb){return -1}let(a,b)=(aa as usize,bb as usize);if findv(&order,n,a).is_none()||findv(&order,n,b).is_none(){return -1}let x=findn(&rows,&deg,a,b);if op==5{res[z]=x.is_some() as i64}else if op==2{if x.is_some()||deg[a]>=34||d==0&&deg[b]>=34{return -1}rows[a][deg[a]]=b;deg[a]+=1;if d==0{rows[b][deg[b]]=a;deg[b]+=1}res[z]=1}else{let Some(x)=x else{return -1};deln(&mut rows,&mut deg,a,x);if d==0{let Some(y)=findn(&rows,&deg,b,a)else{return -1};deln(&mut rows,&mut deg,b,y);}res[z]=1;}},
 4=>{if !(0..32).contains(&aa)||bb!=0{return -1}res[z]=findv(&order,n,aa as usize).is_some() as i64;},
 6=>{if aa!=0||bb!=0{return -1}n=0;deg=[0;32];res[z]=1;},_=>return -1}}
 let mut words=2+ops;for &u in &order[..n]{words+=2+deg[u]}if output.is_null()||capacity<words*8{return -2}let out=unsafe{std::slice::from_raw_parts_mut(output,capacity)};let mut w=0;put(out,w,oo);w+=1;for &x in &res[..ops]{put(out,w,x);w+=1}put(out,w,n as i64);w+=1;for &u in &order[..n]{put(out,w,u as i64);w+=1;put(out,w,deg[u] as i64);w+=1;for j in 0..deg[u]{put(out,w,rows[u][j] as i64);w+=1}}words as i64*8
}
