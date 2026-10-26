package sublinear_bipartiteness_walk_tester
import "core:c"

N :: 16
D :: 4
EDGES :: 32
T :: 4
R :: 8
L :: 8
MAX_INPUT :: 330

put_i64 :: proc(out:[^]u8,value:i64){bits:=u64(value);for byte:=0;byte<8;byte+=1{out[byte]=u8(bits&255);bits>>=8}}

@(export)
sublinear_bipartiteness_walk_tester :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<8||length>MAX_INPUT||input[0]<1||input[0]>N||input[1]<3||input[1]>D||input[2]<0||input[2]>EDGES{return -1}
    n,d,m:=int(input[0]),int(input[1]),int(input[2]);if m>n*d/2{return -1};suffix:=3+2*m
    if length<c.size_t(suffix+4)||input[suffix]<1||input[suffix]>T||input[suffix+1]<1||input[suffix+1]>R||input[suffix+2]<1||input[suffix+2]>L{return -1}
    tc,walks,steps:=int(input[suffix]),int(input[suffix+1]),int(input[suffix+2]);if length!=c.size_t(suffix+3+tc+tc*walks*steps){return -1}
    adjacent:[N][N]bool;neighbors:[N][D]int;degree:[N]int
    for e:=0;e<m;e+=1{a0,b0:=input[3+2*e],input[4+2*e];if a0<0||b0<0||a0>=i64(n)||b0>=i64(n)||a0>=b0{return -1};a,b:=int(a0),int(b0);if adjacent[a][b]||degree[a]>=d||degree[b]>=d{return -1};adjacent[a][b]=true;adjacent[b][a]=true;at:=degree[a];degree[a]+=1;for at>0&&neighbors[a][at-1]>b{neighbors[a][at]=neighbors[a][at-1];at-=1};neighbors[a][at]=b;at=degree[b];degree[b]+=1;for at>0&&neighbors[b][at-1]>a{neighbors[b][at]=neighbors[b][at-1];at-=1};neighbors[b][at]=a}
    startsAt:=suffix+3;drawsAt:=startsAt+tc;for t:=0;t<tc;t+=1{if input[startsAt+t]<0||input[startsAt+t]>=i64(n){return -1}};drawCount:=tc*walks*steps;for i:=0;i<drawCount;i+=1{if input[drawsAt+i]<0||input[drawsAt+i]>=i64(2*d){return -1}}
    accepted:=true;draw:=0;for t:=0;t<tc;t+=1{if !accepted{break};seen:[N][2]bool;start:=int(input[startsAt+t]);seen[start][0]=true;for walk:=0;walk<walks;walk+=1{if !accepted{break};vertex,parity:=start,0;for step:=0;step<steps;step+=1{choice:=int(input[drawsAt+draw]);draw+=1;if choice<degree[vertex]{vertex=neighbors[vertex][choice];parity^=1};seen[vertex][parity]=true;if seen[vertex][1-parity]{accepted=false;break}}}}
    if output==nil||capacity<8{return -2};staged:[8]u8;verdict:=i64(0);if accepted{verdict=1};put_i64(&staged[0],verdict);for i:=0;i<8;i+=1{output[i]=staged[i]};return 8
}
