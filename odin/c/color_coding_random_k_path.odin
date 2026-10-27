package color_coding_random_k_path
import "core:c"

MAX_N :: 12
MAX_M :: 66
MAX_K :: 6
MAX_TRIALS :: 8
MAX_INPUT :: 232
MAX_OUTPUT :: 64
put_i64 :: proc(out:[^]u8,at:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[at+b]=u8(bits&255);bits>>=8}}
path_less :: proc(a:[MAX_K]int,b:[MAX_K]int,length:int)->bool{for i:=0;i<length;i+=1{if a[i]!=b[i]{return a[i]<b[i]}};return false}

@(export)
color_coding_random_k_path :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<4||length>MAX_INPUT{return -1}
    if input[0]<1||input[0]>MAX_N||input[1]<0||input[1]>MAX_M||input[2]<1||input[2]>MAX_K||input[2]>input[0]||input[3]<1||input[3]>MAX_TRIALS{return -1}
    n,m,k,trials:=int(input[0]),int(input[1]),int(input[2]),int(input[3]);edge_start:=4;color_start:=edge_start+2*m
    if length!=c.size_t(color_start+trials*n){return -1}
    adj:[MAX_N]u16
    for e:=0;e<m;e+=1{av,bv:=input[edge_start+2*e],input[edge_start+2*e+1];if av<0||bv<0||av>=i64(n)||bv>=i64(n)||av==bv{return -1};a,b:=int(av),int(bv);if adj[a]&(u16(1)<<u16(b))!=0{return -1};adj[a]|=u16(1)<<u16(b);adj[b]|=u16(1)<<u16(a)}
    for t:=0;t<trials;t+=1{for v:=0;v<n;v+=1{color:=input[color_start+t*n+v];if color<0||color>=i64(k){return -1}}}
    full:=(1<<k)-1
    for trial:=0;trial<trials;trial+=1{
        colors:[MAX_N]int;for v:=0;v<n;v+=1{colors[v]=int(input[color_start+trial*n+v])}
        reachable:[1<<MAX_K][MAX_N]bool
        paths:[1<<MAX_K][MAX_N][MAX_K]int
        for mask:=0;mask<=full;mask+=1{for v:=0;v<n;v+=1{for j:=0;j<k;j+=1{paths[mask][v][j]=-1}}}
        for v:=0;v<n;v+=1{mask:=1<<colors[v];reachable[mask][v]=true;paths[mask][v][0]=v}
        for mask:=1;mask<=full;mask+=1{
            path_len:=0;for bits:=mask;bits!=0;bits&=bits-1{path_len+=1}
            for v:=0;v<n;v+=1{if reachable[mask][v]&&mask!=full{for u:=0;u<n;u+=1{bit:=1<<colors[u];if adj[v]&(u16(1)<<u16(u))==0||mask&bit!=0{continue};next:=mask|bit;candidate:[MAX_K]int;for j:=0;j<path_len;j+=1{candidate[j]=paths[mask][v][j]};candidate[path_len]=u;if !reachable[next][u]||path_less(candidate,paths[next][u],path_len+1){reachable[next][u]=true;for j:=0;j<=path_len;j+=1{paths[next][u][j]=candidate[j]}}}}}
        }
        best:=-1;for v:=0;v<n;v+=1{if reachable[full][v]&&(best<0||path_less(paths[full][v],paths[full][best],k)){best=v}}
        if best>=0{bytes:=8*(k+2);if output==nil||capacity<c.size_t(bytes){return -2};staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,1);put_i64(&staged[0],8,i64(trial+1));for j:=0;j<k;j+=1{put_i64(&staged[0],8*(j+2),i64(paths[full][best][j]))};for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)}
    }
    if output==nil||capacity<16{return -2};staged:[16]u8;put_i64(&staged[0],0,0);put_i64(&staged[0],8,0);for i:=0;i<16;i+=1{output[i]=staged[i]};return 16
}
