#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }
const INF: i64 = i64::MAX / 4;
fn dist_scaled(a: Point,b: Point)->i64{let dx=a.x-b.x;let dy=a.y-b.y;let sq=(dx*dx+dy*dy)*1_000_000;let(mut lo,mut hi)=(0i64,3_000_000i64);while lo<hi{let mid=lo+(hi-lo+1)/2;if mid*mid<=sq{lo=mid}else{hi=mid-1}}let up=lo+1;if up*up-sq<sq-lo*lo{up}else{lo}}
fn add(a:i64,b:i64)->i64{if a>=INF{INF}else{a+b}}
fn solve(outer:&[usize],order:&[usize],p:&[Point])->i64{
 let k=order.len();let mut po=[INF;7];let mut pi=[INF;7];po[0]=0;
 for j in 1..=k{let a=add(po[j-1],dist_scaled(p[outer[0]],p[order[j-1]]));let b=if j>1{add(pi[j-1],dist_scaled(p[order[j-2]],p[order[j-1]]))}else{INF};pi[j]=a.min(b);}
 for i in 1..outer.len(){let mut co=[INF;7];let mut ci=[INF;7];let edge=dist_scaled(p[outer[i-1]],p[outer[i]]);co[0]=add(po[0],edge);
  for j in 1..=k{co[j]=add(po[j],edge).min(add(pi[j],dist_scaled(p[order[j-1]],p[outer[i]])));}
  for j in 1..=k{let a=add(co[j-1],dist_scaled(p[outer[i]],p[order[j-1]]));let b=if j>1{add(ci[j-1],dist_scaled(p[order[j-2]],p[order[j-1]]))}else{INF};ci[j]=a.min(b);}
  po=co;pi=ci;
 }
 let mut best=add(po[k],dist_scaled(p[outer[outer.len()-1]],p[outer[0]]));if k>0{best=best.min(add(pi[k],dist_scaled(p[order[k-1]],p[outer[0]])));}best
}
fn next_perm(a:&mut [usize])->bool{if a.len()<2{return false;}let mut i=a.len()-2;loop{if a[i]<a[i+1]{break;}if i==0{return false;}i-=1;}let mut j=a.len()-1;while a[j]<=a[i]{j-=1;}a.swap(i,j);a[i+1..].reverse();true}
fn put(out:&mut [u8],x:i64){out[..8].copy_from_slice(&x.to_le_bytes());}

#[no_mangle]
pub unsafe extern "C" fn tsp_few_inner_points(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>51{return -1;}let v=std::slice::from_raw_parts(input,length);let(n0,k0)=(v[0],v[1]);
 if n0<3||n0>16||k0<0||k0>6||k0>n0-3||length!=2+3*n0 as usize{return -1;}let n=n0 as usize;let k=k0 as usize;let on=n-k;
 let mut seen=[false;16];let mut outer=Vec::with_capacity(on);let mut inner=Vec::with_capacity(k);
 for i in 0..on{let id=v[2+i];if id<0||id>=n0||seen[id as usize]{return -1;}seen[id as usize]=true;outer.push(id as usize);}
 for i in 0..k{let id=v[2+on+i];if id<0||id>=n0||seen[id as usize]{return -1;}seen[id as usize]=true;inner.push(id as usize);}
 if seen[..n].iter().any(|x|!*x){return -1;}let mut p=Vec::with_capacity(n);let off=2+n;
 for i in 0..n{let(x,y)=(v[off+2*i],v[off+2*i+1]);if !(-1000..=1000).contains(&x)||!(-1000..=1000).contains(&y)||p.iter().any(|q:&Point|q.x==x&&q.y==y){return -1;}p.push(Point{x,y});}
 inner.sort_unstable();let mut best=INF;loop{best=best.min(solve(&outer,&inner,&p));if !next_perm(&mut inner){break;}}
 if output.is_null()||capacity<8{return -2;}let out=std::slice::from_raw_parts_mut(output,8);put(out,best);8
}
