module euler
@[export: 'euler']
pub fn euler(v &i64,n usize)i64{
 if unsafe{v==nil}||n<4||n>516{return -2};count:=unsafe{v[0]};source:=unsafe{v[1]};dest:=unsafe{v[2]};edges:=unsafe{v[3]}
 if count<1||count>32||source<0||source>=count||dest<0||dest>=count||edges<0||edges>256||n!=4+2*int(edges){return -2}
 mut adj:=[32]u64{};mut degree:=[32]i64{}
 for i in 0..int(edges){x:=unsafe{v[4+2*i]};y:=unsafe{v[5+2*i]};if x<0||y<0||x>=count||y>=count||x==y{return -2};bx:=u64(1)<<u32(x);by:=u64(1)<<u32(y);if adj[x]&by!=0{return -2};adj[x]|=by;adj[y]|=bx;degree[x]++;degree[y]++}
 mut odd:=i64(0);for i in 0..int(count){want:=source!=dest&&(i64(i)==source||i64(i)==dest);is_odd:=degree[i]%2!=0;if is_odd!=want{return 0};if is_odd{odd++}}
 if source == dest { return if odd == 0 { 1 } else { 0 } }
 return if odd == 2 { 1 } else { 0 }
}
