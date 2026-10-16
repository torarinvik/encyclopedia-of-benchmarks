#[no_mangle]
pub extern "C" fn euler(v:*const i64,n:usize)->i64{
 if v.is_null()||n<4||n>516{return -2}let a=unsafe{std::slice::from_raw_parts(v,n)};if a[0]<1||a[0]>32||a[1]<0||a[1]>=a[0]||a[2]<0||a[2]>=a[0]||a[3]<0||a[3]>256||n!=4+2*a[3] as usize{return -2}
 let count=a[0] as usize;let s=a[1] as usize;let t=a[2] as usize;let m=a[3] as usize;let mut adj=[0u64;32];let mut deg=[0i32;32];for i in 0..m{let x=a[4+2*i];let y=a[5+2*i];if x<0||y<0||x>=a[0]||y>=a[0]||x==y{return -2}let(x,y)=(x as usize,y as usize);if adj[x]>>y&1!=0{return -2}adj[x]|=1<<y;adj[y]|=1<<x;deg[x]+=1;deg[y]+=1;}
 let mut odd=0;for i in 0..count{let want=if s==t{false}else{i==s||i==t};if (deg[i]&1!=0)!=want{return 0}if deg[i]&1!=0{odd+=1}}if s==t { if odd==0 {1} else {0} } else if odd==2 {1} else {0}
}
