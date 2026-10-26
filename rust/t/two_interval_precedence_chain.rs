// Clean-room longest precedence chain of 2-intervals.
const N:usize=16;const F:usize=17;
fn before(v:*const i64,a:usize,b:usize)->bool{let x=1+4*a;let y=1+4*b;for q in 0..4{let p=unsafe{*v.add(x+q)};let z=unsafe{*v.add(y+q)};if p!=z{return p<z}}a<b}
fn precedes(v:*const i64,a:usize,b:usize)->bool{unsafe{let x=1+4*a;let y=1+4*b;*v.add(x+1)<*v.add(y)&&*v.add(x+3)<*v.add(y+2)}}
fn lexless(a:&[usize;N],an:usize,b:&[usize;N],bn:usize)->bool{for i in 0..an.min(bn){if a[i]!=b[i]{return a[i]<b[i]}}an<bn}
#[no_mangle]
pub unsafe extern "C" fn two_interval_precedence_chain(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{if v.is_null()||n<5||n>65||*v<1||*v>16{return -1}let count=*v as usize;if n!=1+4*count{return -1}for i in 0..count{let p=1+4*i;for q in 0..4{let x=*v.add(p+q);if !(0..=63).contains(&x){return -1}}if *v.add(p)>=*v.add(p+1)||*v.add(p+2)>=*v.add(p+3)||*v.add(p+1)>=*v.add(p+2){return -1}}
 let mut order=[0usize;N];for i in 0..count{order[i]=i}for i in 1..count{let x=order[i];let mut j=i;while j>0&&before(v,x,order[j-1]){order[j]=order[j-1];j-=1}order[j]=x}
 let mut paths=[[0usize;N];N];let mut len=[0usize;N];for i in 0..count{paths[i][0]=order[i];len[i]=1;for j in 0..i{if precedes(v,order[j],order[i]){let mut cand=paths[j];cand[len[j]]=order[i];let m=len[j]+1;if m>len[i]||(m==len[i]&&lexless(&cand,m,&paths[i],len[i])){paths[i]=cand;len[i]=m}}}}
 let mut best=0usize;for i in 1..count{if len[i]>len[best]||(len[i]==len[best]&&lexless(&paths[i],len[i],&paths[best],len[best])){best=i}}let mut fields=[0i64;F];fields[0]=len[best]as i64;for i in 0..len[best]{fields[i+1]=paths[best][i]as i64}let bytes=8*(len[best]+1);if out.is_null()||cap<bytes{return -2}for i in 0..len[best]+1{let b=fields[i].to_le_bytes();std::ptr::copy_nonoverlapping(b.as_ptr(),out.add(8*i),8)}bytes as i64}
