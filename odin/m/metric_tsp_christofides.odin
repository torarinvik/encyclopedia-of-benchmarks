package metric_tsp_christofides
import "core:c"

N :: 8
M :: 256
store :: proc(o:[^]u8,p:int,x:i64){u:=u64(x);for b:=0;b<8;b+=1{o[p+b]=u8(u&255);u>>=8}}

@(export)
metric_tsp_christofides :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2||length>65 do return -1
 n64:=input[0];if n64<1||n64>N||length!=c.size_t(1+n64*n64) do return -1
 n:=int(n64);d:[N][N]i64
 for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{w:=input[1+i*n+j];if w<0||w>10000||(i==j&&w!=0) do return -1;d[i][j]=w}}
 for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{if d[i][j]!=d[j][i] do return -1;for k:=0;k<n;k+=1{if d[i][j]>d[i][k]+d[k][j] do return -1}}}
 bytes:=8*(n+2);if output==nil||capacity<c.size_t(bytes) do return -2
 used:[N][N]bool;tree:[N][N]bool;parent:[N]int;for i:=0;i<n;i+=1{parent[i]=i};accepted:=0
 for step:=0;step<n*(n-1)/2&&accepted<n-1;step+=1{bu,bv:= -1,-1;bw:=i64(9223372036854775807);for u:=0;u<n;u+=1{for v:=u+1;v<n;v+=1{if !used[u][v]&&(d[u][v]<bw||(d[u][v]==bw&&(bu<0||u<bu||(u==bu&&v<bv)))){bu,bv,bw=u,v,d[u][v]}}};used[bu][bv]=true;ru,rv:=bu,bv;for parent[ru]!=ru{ru=parent[ru]};for parent[rv]!=rv{rv=parent[rv]};if ru!=rv{parent[rv]=ru;tree[bu][bv]=true;tree[bv][bu]=true;accepted+=1}}
 odd:[N]int;on:=0;for i:=0;i<n;i+=1{deg:=0;for j:=0;j<n;j+=1{if tree[i][j]{deg+=1}};if deg%2==1{odd[on]=i;on+=1}}
 dp:[M]i64;pick:[M]int;for m:=0;m<M;m+=1{dp[m]=9223372036854775807/4;pick[m]= -1};dp[0]=0;full:=(1<<on)-1
 for mask:=1;mask<=full;mask+=1{i:=0;for (mask&(1<<i))==0{i+=1};rest:=mask^(1<<i);for j:=i+1;j<on;j+=1{if rest&(1<<j)!=0{tail:=rest^(1<<j);val:=dp[tail]+d[odd[i]][odd[j]];if val<dp[mask]{dp[mask]=val;pick[mask]=j}}}}
 multi:[N][N]int;for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{if tree[i][j]{multi[i][j]=1}}};mask:=full
 for mask!=0{i:=0;for (mask&(1<<i))==0{i+=1};j:=pick[mask];u,v:=odd[i],odd[j];multi[u][v]+=1;multi[v][u]+=1;mask^=(1<<i)|(1<<j)}
 stack:[32]int;rev:[32]int;top,rc:=1,0;stack[0]=0
 for top>0{v:=stack[top-1];w:= -1;for x:=0;x<n;x+=1{if multi[v][x]>0{w=x;break}};if w<0{top-=1;rev[rc]=stack[top];rc+=1}else{multi[v][w]-=1;multi[w][v]-=1;stack[top]=w;top+=1}}
 seen:[N]bool;order:[N]int;cnt:=0;for ii:=rc;ii>0;ii-=1{v:=rev[ii-1];if !seen[v]{seen[v]=true;order[cnt]=v;cnt+=1}}
 cost:=i64(0);for i:=0;i<n-1;i+=1{cost+=d[order[i]][order[i+1]]};cost+=d[order[n-1]][0];store(output,0,cost);for i:=0;i<n;i+=1{store(output,8*(i+1),i64(order[i]))};store(output,8*(n+1),0);return i64(bytes)
}
