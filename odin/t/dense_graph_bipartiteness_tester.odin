package dense_graph_bipartiteness_tester
import "core:c"

MAX_N :: 64
MAX_Q :: 16
MAX_INPUT :: 82
MAX_OUTPUT :: 16

has_edge :: proc(row:i64,vertex:int)->bool{return ((u64(row)>>vertex)&1)!=0}
put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=u64(value);for byte:=0;byte<8;byte+=1{out[offset+byte]=u8(bits&255);bits>>=8}}

@(export)
dense_graph_bipartiteness_tester :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<4||length>MAX_INPUT||input[0]<1||input[0]>64||input[1]<1||input[1]>16{return -1}
    n,q:=int(input[0]),int(input[1]);if q>n||length!=c.size_t(2+n+q){return -1}
    for i:=0;i<n;i+=1{row:=input[2+i];if (n<64&&(row<0||(u64(row)>>n)!=0))||has_edge(row,i){return -1};for j:=i+1;j<n;j+=1{if has_edge(row,j)!=has_edge(input[2+j],i){return -1}}}
    remaining:[MAX_N]int;sample:[MAX_Q]int;for i:=0;i<n;i+=1{remaining[i]=i}
    for i:=0;i<q;i+=1{draw:=input[2+n+i];if draw<0||draw>=i64(n-i){return -1};selected:=i+int(draw);temp:=remaining[i];remaining[i]=remaining[selected];remaining[selected]=temp;sample[i]=remaining[i]}
    adjacent:[MAX_Q][MAX_Q]bool
    for i:=0;i<q;i+=1{for j:=i+1;j<q;j+=1{edge:=has_edge(input[2+sample[i]],sample[j]);adjacent[i][j]=edge;adjacent[j][i]=edge}}
    color:[MAX_Q]int;for i:=0;i<q;i+=1{color[i]=-1};accepted:=i64(1)
    for start:=0;start<q;start+=1{if color[start]!=-1{continue};queue:[MAX_Q]int;head,tail:=0,0;queue[tail]=start;tail+=1;color[start]=0;for head<tail{vertex:=queue[head];head+=1;for neighbor:=0;neighbor<q;neighbor+=1{if !adjacent[vertex][neighbor]{continue};if color[neighbor]==-1{color[neighbor]=color[vertex]^1;queue[tail]=neighbor;tail+=1}else if color[neighbor]==color[vertex]{accepted=0}}}}
    if output==nil||capacity<MAX_OUTPUT{return -2};staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,accepted);put_i64(&staged[0],8,i64(q*(q-1)/2));for i:=0;i<MAX_OUTPUT;i+=1{output[i]=staged[i]};return MAX_OUTPUT
}
