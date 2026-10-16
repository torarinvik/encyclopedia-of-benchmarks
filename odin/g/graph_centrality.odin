package graph_centrality
import "core:c"

@(export)
graph_centrality :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
 if input==nil||length<2 do return -1
 nn,ee:=input[0],input[1];if nn<1||nn>16||ee<0||ee>nn*(nn-1)||length!=c.size_t(2+3*ee) do return -1
 d:[16][16]i64;inf:=i64(0x7fffffffffffffff)
 for i:=0;i<int(nn);i+=1{for j:=0;j<int(nn);j+=1{d[i][j]=inf;if i==j{d[i][j]=0}}}
 for z:=0;z<int(ee);z+=1{a,b,w:=input[2+3*z],input[3+3*z],input[4+3*z];if a<0||a>=nn||b<0||b>=nn||a==b||w<1||w>1000000||d[a][b]!=inf do return -1;d[a][b]=w}
 for k:=0;k<int(nn);k+=1{for i:=0;i<int(nn);i+=1{if d[i][k]==inf{continue};for j:=0;j<int(nn);j+=1{if d[k][j]!=inf&&d[i][k]+d[k][j]<d[i][j]{d[i][j]=d[i][k]+d[k][j]}}}}
 c0,m:=i64(-1),i64(-1);be,bh:=inf,f64(-1)
 if nn==1{c0=0;m=0}else{for i:=0;i<int(nn);i+=1{reachable:=false;ec:=i64(0);h:=f64(0);for j:=0;j<int(nn);j+=1{if i!=j&&d[i][j]!=inf{reachable=true;if d[i][j]>ec{ec=d[i][j]};h+=1.0/f64(d[i][j])}};if reachable&&ec<be{be=ec;c0=i64(i)};if reachable&&h>bh{bh=h;m=i64(i)}}}
 if output==nil||capacity<16 do return -2
 vals:=[2]i64{c0,m};for a:=0;a<2;a+=1{bits:=u64(vals[a]);for b:=0;b<8;b+=1{output[a*8+b]=u8(bits>>u64(b*8))}};return 16
}
