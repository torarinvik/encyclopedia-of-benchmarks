package eulerian_trail_undirected_simple
import "core:c"
MAX_V::10
MAX_E::45
dfs::proc "contextless"(u:int,neighbors:[^][MAX_E]int,degree:[^]int,seen:[^][MAX_V]bool,path:[^]i64,count:^int){path[count^]=i64(u);count^+=1;for i:=0;i<degree[u];i+=1{v:=neighbors[u][i];if !seen[u][v]{seen[u][v]=true;seen[v][u]=true;dfs(v,neighbors,degree,seen,path,count)}}}
put::proc "contextless"(out:[^]u8,slot:int,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{out[slot*8+i]=u8(bits>>u64(i*8))}}
@(export)
eulerian_trail_undirected_simple::proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2 do return -1
 n64:=input[0];m64:=input[1];if n64<2||n64>MAX_V||m64<0||m64>MAX_E do return -1
 n:=int(n64);m:=int(m64);if int(length)!=2+2*m do return -1
 neighbors:[MAX_V][MAX_E]int;degree:[MAX_V]int;adjacent:[MAX_V][MAX_V]bool
 for i:=0;i<m;i+=1{a:=input[2+2*i];b:=input[3+2*i];if a<0||b<0||a>=n64||b>=n64||a==b do return -1;u:=int(a);v:=int(b);if adjacent[u][v] do return -1;adjacent[u][v]=true;adjacent[v][u]=true;neighbors[u][degree[u]]=v;degree[u]+=1;neighbors[v][degree[v]]=u;degree[v]+=1}
 odd:=0;start:=1;for v:=0;v<n;v+=1{if degree[v]%2==1{odd+=1;start=v}};if odd!=0&&odd!=2 do return -1;status:=i64(2);if odd==0{status=1;start=1}
 if m>0{if status==1&&degree[1]==0 do return -1;reached:[MAX_V]bool;stack:[MAX_V]int;top:=0;stack[top]=start;top+=1;reached[start]=true;for top>0{top-=1;u:=stack[top];for i:=0;i<degree[u];i+=1{v:=neighbors[u][i];if !reached[v]{reached[v]=true;stack[top]=v;top+=1}}};for v:=0;v<n;v+=1{if degree[v]>0&&!reached[v] do return -1}}
 seen:[MAX_V][MAX_V]bool;path:[MAX_E+1]i64;count:=0;dfs(start,&neighbors,&degree,&seen,&path,&count);if count!=m+1 do return -1;bytes:=(2+count)*8;if output==nil||int(capacity)<bytes do return -2;put(output,0,status);put(output,1,i64(count));for i:=0;i<count;i+=1{put(output,2+i,path[i])};return i64(bytes)
}
