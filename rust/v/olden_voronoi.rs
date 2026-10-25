use std::ffi::c_void;

const MAX_POINTS: usize = 5;
const MAX_EDGES: usize = 32;
const SCALE: f64 = 1000.0;
#[derive(Clone, Copy, Default)] struct Point { x: f64, y: f64, norm: f64 }
#[derive(Clone, Copy, Default)] struct EdgePair { left: i32, right: i32 }
struct State { points: [Point; MAX_POINTS], left: [i32; MAX_POINTS], right: [i32; MAX_POINTS], onext: [i32; MAX_EDGES*4], origin: [i32; MAX_EDGES*4], alive: [bool; MAX_EDGES], edge_count: usize }
impl State {
 fn new() -> Self { Self { points:[Point::default();MAX_POINTS],left:[-1;MAX_POINTS],right:[-1;MAX_POINTS],onext:[0;MAX_EDGES*4],origin:[0;MAX_EDGES*4],alive:[false;MAX_EDGES],edge_count:0 } }
 fn sym(e:i32)->i32{e^2} fn rot(e:i32)->i32{(e&!3)|((e+1)&3)} fn rotinv(e:i32)->i32{(e&!3)|((e+3)&3)}
 fn lnext(&self,e:i32)->i32{Self::rot(self.onext[Self::rotinv(e) as usize])}
 fn oprev(&self,e:i32)->i32{Self::rot(self.onext[Self::rot(e) as usize])}
 fn rprev(&self,e:i32)->i32{self.onext[Self::sym(e) as usize]}
 fn lprev(&self,e:i32)->i32{Self::sym(self.onext[e as usize])}
 fn orig(&self,e:i32)->i32{self.origin[e as usize]} fn dest(&self,e:i32)->i32{self.origin[Self::sym(e) as usize]}
 fn ccw(&self,a:i32,b:i32,c:i32)->bool{let a=self.points[a as usize];let b=self.points[b as usize];let c=self.points[c as usize];(a.x-c.x)*(b.y-c.y)-(b.x-c.x)*(a.y-c.y)>0.0}
 fn incircle(&self,a:i32,b:i32,c:i32,d:i32)->bool{let a=self.points[a as usize];let b=self.points[b as usize];let c=self.points[c as usize];let d=self.points[d as usize];let adx=a.x-d.x;let ady=a.y-d.y;let bdx=b.x-d.x;let bdy=b.y-d.y;let cdx=c.x-d.x;let cdy=c.y-d.y;(a.norm-d.norm)*(bdx*cdy-bdy*cdx)+(b.norm-d.norm)*(cdx*ady-cdy*adx)+(c.norm-d.norm)*(adx*bdy-ady*bdx)>0.0}
 fn make_edge(&mut self,a:i32,b:i32)->i32{let e=(self.edge_count*4) as i32;self.edge_count+=1;self.alive[e as usize/4]=true;self.onext[e as usize]=e;self.origin[e as usize]=a;self.onext[(e+1) as usize]=e+3;self.onext[(e+2) as usize]=e+2;self.origin[(e+2) as usize]=b;self.onext[(e+3) as usize]=e+1;e}
 fn splice(&mut self,a:i32,b:i32){let alpha=Self::rot(self.onext[a as usize]);let beta=Self::rot(self.onext[b as usize]);let t1=self.onext[beta as usize];let temp=self.onext[alpha as usize];self.onext[alpha as usize]=t1;self.onext[beta as usize]=temp;let temp=self.onext[a as usize];let t1=self.onext[b as usize];self.onext[b as usize]=temp;self.onext[a as usize]=t1;}
 fn connect_left(&mut self,a:i32,b:i32)->i32{let e=self.make_edge(self.dest(a),self.orig(b));self.splice(e,self.lnext(a));self.splice(Self::sym(e),b);e}
 fn connect_right(&mut self,a:i32,b:i32)->i32{let e=self.make_edge(self.dest(a),self.orig(b));self.splice(e,Self::sym(a));self.splice(Self::sym(e),self.oprev(b));e}
 fn delete_edge(&mut self,e:i32){let f=self.oprev(e);self.splice(e,f);let f=self.oprev(Self::sym(e));self.splice(Self::sym(e),f);self.alive[e as usize/4]=false;}
 fn valid(&self,l:i32,base:i32)->bool{self.ccw(self.orig(base),self.dest(l),self.dest(base))}
 fn merge(&mut self,ldo:i32,mut ldi:i32,mut rdi:i32,mut rdo:i32)->EdgePair{
  loop{let t3=self.orig(rdi);let mut t1=self.orig(ldi);let mut t2=self.dest(ldi);while self.ccw(t1,t2,t3){ldi=self.lnext(ldi);t1=self.orig(ldi);t2=self.dest(ldi);}t2=self.dest(rdi);if self.ccw(t2,t3,t1){rdi=self.rprev(rdi)}else{break}}
  let mut basel=self.connect_left(Self::sym(rdi),ldi);let mut lcand=self.rprev(basel);let mut rcand=self.oprev(basel);let t1=self.orig(basel);let t2=self.dest(basel);if t1==self.orig(rdo){rdo=basel}let mut ldo=ldo;if t2==self.orig(ldo){ldo=Self::sym(basel)}
  loop{let mut t=self.onext[lcand as usize];if self.valid(t,basel){let v4=self.orig(basel);let mut v1=self.dest(lcand);let v3=self.orig(lcand);let mut v2=self.dest(t);while self.incircle(v1,v2,v3,v4){self.delete_edge(lcand);lcand=t;t=self.onext[lcand as usize];v1=self.dest(lcand);let v3=self.orig(lcand);v2=self.dest(t);}}
   t=self.oprev(rcand);if self.valid(t,basel){let v4=self.dest(basel);let mut v1=self.dest(t);let mut v2=self.dest(rcand);let v3=self.orig(rcand);while self.incircle(v1,v2,v3,v4){self.delete_edge(rcand);rcand=t;t=self.oprev(rcand);v2=self.dest(rcand);let v3=self.orig(rcand);v1=self.dest(t);}}
   let lv=self.valid(lcand,basel);let rv=self.valid(rcand,basel);if !lv&&!rv{return EdgePair{left:ldo,right:rdo}}
   let v1=self.dest(lcand);let v2=self.orig(lcand);let v3=self.orig(rcand);let v4=self.dest(rcand);
   if !lv||(rv&&self.incircle(v1,v2,v3,v4)){basel=self.connect_left(rcand,Self::sym(basel));rcand=self.lnext(Self::sym(basel));}else{basel=Self::sym(self.connect_right(lcand,basel));lcand=self.rprev(basel);}
  }
 }
 fn get_low(&self,mut node:i32)->i32{while self.left[node as usize]>=0{node=self.left[node as usize]}node}
 fn build(&mut self,tree:i32,extra:i32)->EdgePair{
  if tree>=0&&self.right[tree as usize]>=0{let minx=self.get_low(tree);let dr=self.build(self.right[tree as usize],extra);let dl=self.build(self.left[tree as usize],tree);let mut r=self.merge(dl.left,dl.right,dr.left,dr.right);while self.orig(r.left)!=minx{r.left=self.rprev(r.left)}while self.orig(r.right)!=extra{r.right=self.lprev(r.right)}return r}
  if tree<0{return EdgePair{left:-1,right:-1}}
  if self.left[tree as usize]<0{let e=self.make_edge(tree,extra);return EdgePair{left:e,right:Self::sym(e)}}
  let s1=self.left[tree as usize];let s2=tree;let s3=extra;let a=self.make_edge(s1,s2);let b=self.make_edge(s2,s3);self.splice(Self::sym(a),b);let c=self.connect_left(b,a);if self.ccw(s1,s3,s2){return EdgePair{left:Self::sym(c),right:c}}let result=EdgePair{left:a,right:Self::sym(b)};if !self.ccw(s1,s2,s3){self.delete_edge(c)}result
 }
 fn center(&self,a:i32,b:i32,c:i32)->(f64,f64){let a=self.points[a as usize];let b=self.points[b as usize];let c=self.points[c as usize];let vx=b.x-a.x;let vy=b.y-a.y;let wx=c.x-a.x;let wy=c.y-a.y;let d3=vx*wy-vy*wx;let d2=-2.0*d3;let d4=(c.x-b.x)*wx+(c.y-b.y)*wy;(0.5*(a.x+b.x)+(d4/d2)*vy,0.5*(a.y+b.y)-(d4/d2)*vx)}
 fn face_center(&self,e:i32)->Option<(f64,f64)>{let e2=self.lnext(e);let e3=self.lnext(e2);if self.lnext(e3)!=e{return None}let a=self.orig(e);let b=self.dest(e);let c=self.dest(e2);if a==b||b==c||a==c||!self.ccw(a,b,c){return None}Some(self.center(a,b,c))}
}
fn quantize(v:f64)->i64{(v*SCALE+0.5).floor() as i64}

#[no_mangle]
pub unsafe extern "C" fn olden_voronoi(input:*const i64,length:usize)->i64{
 if input.is_null()||(length!=7&&length!=11){return -1}let count_value=*input;if count_value!=3&&count_value!=5{return -1}let n=count_value as usize;if length!=1+2*n{return -1}
 let mut s=State::new();for i in 0..n{let x=*input.add(1+2*i);let y=*input.add(2+2*i);if !(-8..=8).contains(&x)||!(-8..=8).contains(&y){return -1}if i>0&&*input.add(1+2*(i-1))>=x{return -1}s.points[i]=Point{x:x as f64,y:y as f64,norm:(x*x+y*y) as f64};}
 if n==3{s.left[1]=0}else{s.left[2]=1;s.right[2]=3;s.left[1]=0}
 for a in 0..n{for b in a+1..n{for c in b+1..n{if !s.ccw(a as i32,b as i32,c as i32)&&!s.ccw(a as i32,c as i32,b as i32){return -1}}}}
 if n==5{for a in 0..n{for b in a+1..n{for c in b+1..n{for d in c+1..n{if !s.incircle(a as i32,b as i32,c as i32,d as i32)&&!s.incircle(a as i32,c as i32,b as i32,d as i32){return -1}}}}}}
 let _hull=s.build(if n==3{1}else{2},(n-1) as i32);let mut seen=[[0i32;3];16];let mut faces=0i64;let mut edges=0i64;let mut dual=0i64;let mut rays=0i64;let mut projection=0i64;
 for edge in 0..s.edge_count{if s.alive[edge]{let e=(4*edge) as i32;let left=s.face_center(e);if let Some((x,y))=left{let a=s.orig(e);let b=s.dest(e);let c=s.dest(s.lnext(e));let mut duplicate=false;for f in 0..faces as usize{if (seen[f][0]==a||seen[f][1]==a||seen[f][2]==a)&&(seen[f][0]==b||seen[f][1]==b||seen[f][2]==b)&&(seen[f][0]==c||seen[f][1]==c||seen[f][2]==c){duplicate=true}}if !duplicate{seen[faces as usize]=[a,b,c];faces+=1;projection+=quantize(x)+2*quantize(y)}}let right=s.face_center(State::sym(e));if left.is_some()||right.is_some(){edges+=1;if left.is_some()&&right.is_some(){dual+=1}else{rays+=1}}}}
 projection+100*faces+10*dual+rays+edges
}
