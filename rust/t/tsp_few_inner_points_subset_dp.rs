#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }
const INF: i64 = i64::MAX / 4;
fn dist_scaled(a: Point,b: Point)->i64{let dx=a.x-b.x;let dy=a.y-b.y;let sq=(dx*dx+dy*dy)*1_000_000;let(mut lo,mut hi)=(0i64,3_000_000i64);while lo<hi{let mid=lo+(hi-lo+1)/2;if mid*mid<=sq{lo=mid}else{hi=mid-1}}let up=lo+1;if up*up-sq<sq-lo*lo{up}else{lo}}
fn add(a:i64,b:i64)->i64{if a>=INF{INF}else{a+b}}
fn solve_subset(outer:&[usize],inner:&[usize],p:&[Point])->i64{
 let k=inner.len();let states=1usize<<k;let sentinel=k;let mut previous=[INF;448];previous[sentinel]=0;
 for mask in 0..states{for last in 0..=k{
  if last<k&&mask&(1usize<<last)==0{continue;}let prefix=previous[mask*7+last];if prefix>=INF{continue;}
  let vertex=if last==sentinel{outer[0]}else{inner[last]};
  for next in 0..k{let bit=1usize<<next;if mask&bit!=0{continue;}let next_mask=mask|bit;
   let candidate=add(prefix,dist_scaled(p[vertex],p[inner[next]]));previous[next_mask*7+next]=previous[next_mask*7+next].min(candidate);
  }
 }}
 for i in 1..outer.len(){let mut current=[INF;448];
  for mask in 0..states{for last in 0..=k{
   if last<k&&mask&(1usize<<last)==0{continue;}let prefix=previous[mask*7+last];if prefix>=INF{continue;}
   let vertex=if last==sentinel{outer[i-1]}else{inner[last]};let candidate=add(prefix,dist_scaled(p[vertex],p[outer[i]]));
   current[mask*7+sentinel]=current[mask*7+sentinel].min(candidate);
  }}
  for mask in 0..states{for last in 0..=k{
   if last<k&&mask&(1usize<<last)==0{continue;}let prefix=current[mask*7+last];if prefix>=INF{continue;}
   let vertex=if last==sentinel{outer[i]}else{inner[last]};
   for next in 0..k{let bit=1usize<<next;if mask&bit!=0{continue;}let next_mask=mask|bit;
    let candidate=add(prefix,dist_scaled(p[vertex],p[inner[next]]));current[next_mask*7+next]=current[next_mask*7+next].min(candidate);
   }
  }}
  previous=current;
 }
 let full=states-1;let mut best=INF;
 for last in 0..=k{if last<k&&full&(1usize<<last)==0{continue;}let vertex=if last==sentinel{outer[outer.len()-1]}else{inner[last]};
  best=best.min(add(previous[full*7+last],dist_scaled(p[vertex],p[outer[0]])));
 }best
}
fn put(out:&mut [u8],x:i64){out[..8].copy_from_slice(&x.to_le_bytes());}

#[no_mangle]
pub unsafe extern "C" fn tsp_few_inner_points_subset_dp(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>51{return -1;}let v=std::slice::from_raw_parts(input,length);let(n0,k0)=(v[0],v[1]);
 if n0<3||n0>16||k0<0||k0>6||k0>n0-3||length!=2+3*n0 as usize{return -1;}let n=n0 as usize;let k=k0 as usize;let on=n-k;
 let mut seen=[false;16];let mut outer=Vec::with_capacity(on);let mut inner=Vec::with_capacity(k);
 for i in 0..on{let id=v[2+i];if id<0||id>=n0||seen[id as usize]{return -1;}seen[id as usize]=true;outer.push(id as usize);}
 for i in 0..k{let id=v[2+on+i];if id<0||id>=n0||seen[id as usize]{return -1;}seen[id as usize]=true;inner.push(id as usize);}
 if seen[..n].iter().any(|x|!*x){return -1;}let mut p=Vec::with_capacity(n);let off=2+n;
 for i in 0..n{let(x,y)=(v[off+2*i],v[off+2*i+1]);if !(-1000..=1000).contains(&x)||!(-1000..=1000).contains(&y)||p.iter().any(|q:&Point|q.x==x&&q.y==y){return -1;}p.push(Point{x,y});}
 let best=solve_subset(&outer,&inner,&p);
 if output.is_null()||capacity<8{return -2;}let out=std::slice::from_raw_parts_mut(output,8);put(out,best);8
}
