package euler
import "core:c"
@(export)
euler :: proc "c" (v:[^]i64,n:c.size_t)->i64 {
 if v==nil||n<4||n>516 do return -2
 count:=v[0];source:=v[1];dest:=v[2];edges:=v[3]
 if count<1||count>32||source<0||source>=count||dest<0||dest>=count||edges<0||edges>256||n!=c.size_t(4+2*edges)do return -2
 adj:[32]u64;degree:[32]i64
 for i:=0;i<32;i+=1{adj[i]=0;degree[i]=0}
 for i:=0;i<int(edges);i+=1{x:=v[4+2*i];y:=v[5+2*i];if x<0||y<0||x>=count||y>=count||x==y do return -2;bx:=u64(1)<<u32(x);by:=u64(1)<<u32(y);if adj[x]&by!=0 do return -2;adj[x]|=by;adj[y]|=bx;degree[x]+=1;degree[y]+=1}
 odd:=i64(0)
 for i:=0;i<int(count);i+=1{want:=source!=dest&&(i64(i)==source||i64(i)==dest);is_odd:=degree[i]%2!=0;if is_odd!=want do return 0;if is_odd do odd+=1}
 if source==dest { if odd==0 do return 1 } else { if odd==2 do return 1 }
 return 0
}
