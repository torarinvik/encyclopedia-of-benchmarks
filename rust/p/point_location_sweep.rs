#[derive(Clone, Copy)]
struct Point { x: i64, y: i64 }
#[derive(Clone, Copy)]
struct Edge { u: usize, v: usize, face: i64 }
#[derive(Clone, Copy, Eq, PartialEq)]
struct Event { x: i64, kind: i64, id: usize }
fn orient(a: Point,b: Point,c: Point)->i64 {(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)}
fn between(x:i64,a:i64,b:i64)->bool {x>=a.min(b)&&x<=a.max(b)}
fn on_segment(a:Point,b:Point,p:Point)->bool {orient(a,b,p)==0&&between(p.x,a.x,b.x)&&between(p.y,a.y,b.y)}
fn intersects(a:Point,b:Point,c:Point,d:Point)->bool {
 let (o1,o2,o3,o4)=(orient(a,b,c),orient(a,b,d),orient(c,d,a),orient(c,d,b));
 if (o1==0&&on_segment(a,b,c))||(o2==0&&on_segment(a,b,d))||(o3==0&&on_segment(c,d,a))||(o4==0&&on_segment(c,d,b)){return true;}
 ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0))
}
fn endpoints(points:&[Point],edges:&[Edge],e:usize)->(Point,Point){let a=points[edges[e].u];let b=points[edges[e].v];if a.x<b.x{(a,b)}else{(b,a)}}
fn height(points:&[Point],edges:&[Edge],e:usize,x:i64)->(i64,i64){let(l,r)=endpoints(points,edges,e);let d=r.x-l.x;(l.y*d+(r.y-l.y)*(x-l.x),d)}
fn edge_less(points:&[Point],edges:&[Edge],a:usize,b:usize,x:i64)->bool {
 let(na,da)=height(points,edges,a,x);let(nb,db)=height(points,edges,b,x);
 if na*db!=nb*da{return na*db<nb*da;}
 let(la,ra)=endpoints(points,edges,a);let(lb,rb)=endpoints(points,edges,b);
 let(sa,sb)=((ra.y-la.y)*(rb.x-lb.x),(rb.y-lb.y)*(ra.x-la.x));if sa!=sb{sa<sb}else{a<b}
}
fn solve(a:&[i64])->i64 {
 if a.len()<4||a.len()>141{return -1;}let(n,m,q,f)=(a[0],a[1],a[2],a[3]);
 if !(2..=16).contains(&n)||!(1..=24).contains(&m)||!(0..=16).contains(&q)||!(1..=16).contains(&f)||a.len()!=(4+2*n+3*m+2*q)as usize{return -1;}
 let(mut pos,nn,mm,qq)=(4usize,n as usize,m as usize,q as usize);
 let mut points=Vec::with_capacity(nn);for _ in 0..nn{let p=Point{x:a[pos],y:a[pos+1]};pos+=2;if !(-300..=300).contains(&p.x)||!(-300..=300).contains(&p.y)||points.iter().any(|v:&Point|v.x==p.x){return -1;}points.push(p);}
 let mut edges=Vec::with_capacity(mm);for _ in 0..mm{let(u,v,face)=(a[pos],a[pos+1],a[pos+2]);pos+=3;if u<0||u>=n||v<0||v>=n||u==v||face< -1||face>=f{return -1;}if edges.iter().any(|e:&Edge|(e.u==u as usize&&e.v==v as usize)||(e.u==v as usize&&e.v==u as usize)){return -1;}edges.push(Edge{u:u as usize,v:v as usize,face});}
 for i in 0..mm{for j in 0..i{let e=edges[i];let g=edges[j];let shared=if e.u==g.u||e.u==g.v{Some(e.u)}else if e.v==g.u||e.v==g.v{Some(e.v)}else{None};if let Some(s)=shared{let oi=if e.u==s{e.v}else{e.u};let oj=if g.u==s{g.v}else{g.u};if orient(points[s],points[oi],points[oj])==0{return -1;}}else if intersects(points[e.u],points[e.v],points[g.u],points[g.v]){return -1;}}}
 let mut queries=Vec::with_capacity(qq);for _ in 0..qq{let(x,y)=(a[pos],a[pos+1]);pos+=2;if !(-300..=300).contains(&x)||!(-300..=300).contains(&y)||points.iter().any(|p|p.x==x){return -1;}queries.push((x,y));}
 let mut events=Vec::with_capacity(2*mm+qq);for e in 0..mm{let(l,r)=endpoints(&points,&edges,e);events.push(Event{x:l.x,kind:1,id:e});events.push(Event{x:r.x,kind:0,id:e});}for(i,&(x,_))in queries.iter().enumerate(){events.push(Event{x,kind:2,id:i});}events.sort_by_key(|e|(e.x,e.kind,e.id));
 let mut active:Vec<usize>=Vec::with_capacity(mm);let mut responses=vec![0i64;qq];
 for event in events{if event.kind==0{if let Some(k)=active.iter().position(|&e|e==event.id){active.remove(k)}else{return -1;}}else if event.kind==1{let mut k=0;while k<active.len()&&edge_less(&points,&edges,active[k],event.id,event.x){k+=1;}active.insert(k,event.id);}else{let(x,y)=queries[event.id];let(mut lo,mut hi)=(0,active.len());while lo<hi{let mid=(lo+hi)/2;let(num,den)=height(&points,&edges,active[mid],x);if num<y*den{lo=mid+1}else{hi=mid;}}if lo<active.len(){let(num,den)=height(&points,&edges,active[lo],x);if num==y*den{responses[event.id]=f+active[lo] as i64+1;}else if lo>0&&edges[active[lo-1]].face>=0{responses[event.id]=edges[active[lo-1]].face+1;}}else if lo>0&&edges[active[lo-1]].face>=0{responses[event.id]=edges[active[lo-1]].face+1;}}}
 responses.iter().enumerate().map(|(i,&r)|(i as i64+1)*r).sum()
}
#[no_mangle]
pub unsafe extern "C" fn point_location_sweep(values:*const i64,length:usize)->i64{if values.is_null()||length>141{return -1;}solve(std::slice::from_raw_parts(values,length))}
