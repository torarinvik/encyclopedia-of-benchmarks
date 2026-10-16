const N:usize=24; const E:usize=2*N+N*(N-1)/2; const P:usize=N*(N-1)/2;
#[derive(Clone,Copy,Default)] struct S{x1:i64,y1:i64,x2:i64,y2:i64}
#[derive(Clone,Copy,Default)] struct Ev{x:i64,y:i64,a:usize,b:usize,t:u8,done:bool}
fn cross(ax:i64,ay:i64,bx:i64,by:i64)->i64{ax*by-ay*bx}
fn inter(a:S,b:S)->Option<(i64,i64)>{let(rx,ry,sx,sy)=(a.x2-a.x1,a.y2-a.y1,b.x2-b.x1,b.y2-b.y1);let(mut d,mut t,mut u)=(cross(rx,ry,sx,sy),cross(b.x1-a.x1,b.y1-a.y1,sx,sy),cross(b.x1-a.x1,b.y1-a.y1,rx,ry));if d==0{return None}if d<0{d=-d;t=-t;u=-u}if t<=0||t>=d||u<=0||u>=d{return None}let(xn,yn)=(a.x1*d+t*rx,a.y1*d+t*ry);if xn%d!=0||yn%d!=0{return None}Some((xn/d,yn/d))}
fn less(s:&[S;N],a:usize,b:usize,x:i64)->bool{let(da,db)=(s[a].x2-s[a].x1,s[b].x2-s[b].x1);let(na,nb)=(s[a].y1*da+(x-s[a].x1)*(s[a].y2-s[a].y1),s[b].y1*db+(x-s[b].x1)*(s[b].y2-s[b].y1));let c=na*db-nb*da;if c!=0{return c<0}let sl=(s[a].y2-s[a].y1)*db-(s[b].y2-s[b].y1)*da;if sl!=0{sl<0}else{a<b}}
unsafe fn put(out:*mut u8,slot:usize,v:i64){let b=v as u64;for i in 0..8{*out.add(slot*8+i)=(b>>(8*i)) as u8}}
#[no_mangle] pub unsafe extern "C" fn bentley_ottmann(input:*const i64,len:usize,out:*mut u8,cap:usize)->i64{
 if input.is_null()||len<1{return -1}let z=std::slice::from_raw_parts(input,len);if z[0]<0||z[0]>N as i64||len!=1+4*z[0] as usize{return -1}let n=z[0] as usize;let mut s=[S::default();N];for i in 0..n{let(x1,y1,x2,y2)=(z[1+4*i],z[2+4*i],z[3+4*i],z[4+4*i]);if !(-1000..=1000).contains(&x1)||!(-1000..=1000).contains(&x2)||!(-1000..=1000).contains(&y1)||!(-1000..=1000).contains(&y2)||x1==x2{return -1}s[i]=if x1<x2{S{x1,y1,x2,y2}}else{S{x1:x2,y1:y2,x2:x1,y2:y1}}}
 let mut ev=[Ev::default();E];let mut ec=0;for i in 0..n{ev[ec]=Ev{x:s[i].x1,y:s[i].y1,a:i,b:0,t:0,done:false};ec+=1;ev[ec]=Ev{x:s[i].x2,y:s[i].y2,a:i,b:0,t:1,done:false};ec+=1}let mut sched=[[false;N];N];let mut active=[0usize;N];let mut ac=0;let mut pts=[(0i64,0i64);P];let mut pc=0;
 loop{let mut ei=ec;for j in 0..ec{if !ev[j].done&&(ei==ec||ev[j].x<ev[ei].x||(ev[j].x==ev[ei].x&&ev[j].y<ev[ei].y)){ei=j}}if ei==ec{break}let e=ev[ei];ev[ei].done=true;if e.t==0{active[ac]=e.a;ac+=1}else if e.t==1{if let Some(j)=(0..ac).find(|&j|active[j]==e.a){for k in j+1..ac{active[k-1]=active[k]}ac-=1}}else{pts[pc]=(e.x,e.y);pc+=1}
 for i in 1..ac{let v=active[i];let mut j=i;while j>0&&less(&s,v,active[j-1],e.x){active[j]=active[j-1];j-=1}active[j]=v}
 for i in 1..ac{let(a,b)=(active[i-1],active[i]);if sched[a][b]{continue}if let Some((x,y))=inter(s[a],s[b]){if x>e.x{if ec>=E{return -1}ev[ec]=Ev{x,y,a,b,t:2,done:false};ec+=1;sched[a][b]=true;sched[b][a]=true}}}
 }
 pts[..pc].sort();let bytes=(1+2*pc)*8;if out.is_null()||cap<bytes{return -2}put(out,0,pc as i64);for i in 0..pc{put(out,1+2*i,pts[i].0);put(out,2+2*i,pts[i].1)}bytes as i64
}
