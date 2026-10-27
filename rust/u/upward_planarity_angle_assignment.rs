// Clean-room fixed-embedding angle-assignment flow profile, DOI 653.
const N:usize=8; const M:usize=18; const F:usize=12;
unsafe fn aug(t:usize,ns:usize,slots:&[usize;N],terms:&[usize;N],inc:&[[bool;F];N],owner:&mut[i32;N],seen:&mut[bool;N],assigned:&mut[i32;N])->bool{
 for s in 0..ns { if inc[terms[t]][slots[s]]&&!seen[s] { seen[s]=true;let old=owner[s];if old<0||aug(old as usize,ns,slots,terms,inc,owner,seen,assigned){owner[s]=t as i32;assigned[t]=s as i32;return true;} } } false
}
unsafe fn suffix(first:usize,r:usize,f:usize,caps:&[i32;12],slots:&mut[usize;N],terms:&[usize;N],inc:&[[bool;F];N])->bool{
 let mut ns=0;let mut owner=[-1i32;N];let mut assigned=[-1i32;N];for face in 0..f{for _ in 0..caps[face]{slots[ns]=face;ns+=1;}}
 for t in first..r{let mut seen=[false;N];if !aug(t,ns,slots,terms,inc,&mut owner,&mut seen,&mut assigned){return false;}}true
}
#[no_mangle]
pub unsafe extern "C" fn upward_planarity_angle_assignment(a:*const i64,len:usize,out:*mut u8,capacity:usize)->i64{
 if a.is_null()||len<4||len>124{return -1;}let x=core::slice::from_raw_parts(a,len);let(nm,mc,fc,outer)=(x[0],x[1],x[2],x[3]);if nm<2||nm>8||mc<1||mc>18||fc<1||fc>12||outer<0||outer>=fc||len!=4+6*mc as usize+fc as usize{return -1;}let(n,m,f,o)=(nm as usize,mc as usize,fc as usize,outer as usize);
 let mut eu=[0usize;18];let mut ev=[0usize;18];let mut adj=[[false;8];8];let mut oe=[[false;8];8];let mut indeg=[0usize;8];
 for i in 0..m{let u=x[4+2*i];let v=x[5+2*i];if u<0||u as usize>=n||v<0||v as usize>=n||u==v||i>0&&(eu[i-1]>u as usize||eu[i-1]==u as usize&&ev[i-1]>=v as usize){return -1;}for j in 0..i{if eu[j]==u as usize&&ev[j]==v as usize||eu[j]==v as usize&&ev[j]==u as usize{return -1;}}eu[i]=u as usize;ev[i]=v as usize;adj[u as usize][v as usize]=true;adj[v as usize][u as usize]=true;oe[u as usize][v as usize]=true;indeg[v as usize]+=1;}
 let mut wl=[0usize;12];let mut wu=[0usize;36];let mut wv=[0usize;36];let mut dart=[[false;8];8];let mut cursor=4+2*m;let mut total=0;
 for j in 0..f{let k=x[cursor];cursor+=1;if k<1||k as usize>2*m||total+k as usize>2*m{return -1;}wl[j]=k as usize;for _ in 0..k{let u=x[cursor];let v=x[cursor+1];cursor+=2;if u<0||v<0||u as usize>=n||v as usize>=n||!adj[u as usize][v as usize]||dart[u as usize][v as usize]{return -1;}dart[u as usize][v as usize]=true;wu[total]=u as usize;wv[total]=v as usize;total+=1;}}
 if cursor!=len||total!=2*m||n as i64-mc+fc!=2{return -1;}for i in 0..m{if !dart[eu[i]][ev[i]]||!dart[ev[i]][eu[i]]{return -1;}}
 let mut succ=[[-1i32;8];8];let mut corner=[[-1i32;8];12];let mut inc=[[false;12];8];let mut sw=[[0i32;2];12];cursor=0;
 for j in 0..f{let k=wl[j];let base=cursor;for i in 0..k{let u=wu[cursor];let v=wv[cursor];let w=wv[base+(i+1)%k];if v!=wu[base+(i+1)%k]||succ[v][u]>=0{return -1;}succ[v][u]=w as i32;if corner[j][v]<0{corner[j][v]=i as i32;}inc[v][j]=true;if oe[v][u]&&oe[v][w]{sw[j][0]+=1;}if !oe[v][u]&&!oe[v][w]{sw[j][1]+=1;}cursor+=1;}}
 let mut seen=[false;8];let mut q=[0usize;8];let(mut h,mut t)=(0,0);q[t]=0;t+=1;seen[0]=true;while h<t{let u=q[h];h+=1;for v in 0..n{if adj[u][v]&&!seen[v]{seen[v]=true;q[t]=v;t+=1;}}}for v in 0..n{if !seen[v]{return -1;}}
 let mut deg=[0usize;8];let mut topo=[0usize;8];h=0;t=0;for v in 0..n{deg[v]=indeg[v];if deg[v]==0{topo[t]=v;t+=1;}}let mut removed=0;while h<t{let u=topo[h];h+=1;removed+=1;for v in 0..n{if oe[u][v]{deg[v]-=1;if deg[v]==0{topo[t]=v;t+=1;}}}}if removed!=n{return -1;}
 for v in 0..n{let d=adj[v].iter().take(n).filter(|&&b|b).count();if d>0{let mut start=0;for u in 0..n{if adj[v][u]{if succ[v][u]<0{return -1;}start=u;}}let(mut cur,mut count,mut trans)=(start,0,0);loop{count+=1;if count>d{return -1;}let next=succ[v][cur] as usize;if oe[v][cur]!=oe[v][next]{trans+=1;}cur=next;if cur==start{break;}}if count!=d||trans!=0&&trans!=2{return -1;}}}
 let mut caps=[0i32;12];let mut sum=0;let mut feasible=true;for j in 0..f{if sw[j][0]!=sw[j][1]{return -1;}caps[j]=sw[j][0]+if j==o{1}else{-1};if caps[j]<0{feasible=false;}sum+=caps[j];}
 let mut terms=[0usize;8];let mut r=0;for v in 0..n{let od=oe[v].iter().take(n).filter(|&&b|b).count();if indeg[v]==0||od==0{terms[r]=v;r+=1;}}if sum!=r as i32{feasible=false;}if out.is_null()||capacity<8*(2+3*r){return -2;}
 let mut slots=[0usize;8];let mut chosen=[-1i32;8];let mut ok=feasible;for i in 0..r{if !ok{break;}let mut found=false;for face in 0..f{if inc[terms[i]][face]&&caps[face]>0{caps[face]-=1;if suffix(i+1,r,f,&caps,&mut slots,&terms,&inc){chosen[i]=face as i32;found=true;break;}caps[face]+=1;}}if !found{ok=false;}}
 let mut words=[0i64;26];words[0]=if ok{1}else{0};words[1]=r as i64;let mut z=2;for i in 0..r{if ok{let face=chosen[i] as usize;words[z]=terms[i] as i64;words[z+1]=face as i64;words[z+2]=corner[face][terms[i]] as i64;}else{words[z]= -1;words[z+1]= -1;words[z+2]= -1;}z+=3;}for i in 0..z{let b=words[i].to_le_bytes();for j in 0..8{*out.add(i*8+j)=b[j];}}(z*8) as i64
}
