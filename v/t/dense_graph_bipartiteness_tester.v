module dense_graph_bipartiteness_tester
const max_n=64
const max_q=16
const max_input=82

fn has_edge(row i64,vertex int) bool {return ((u64(row)>>vertex)&1)!=0}
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}

@[export:'dense_graph_bipartiteness_tester']
pub fn dense_graph_bipartiteness_tester(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{
    if input==nil||length<4||length>max_input||input[0]<1||input[0]>64||input[1]<1||input[1]>16{return -1}
    n,q:=int(input[0]),int(input[1]);if q>n||length!=usize(2+n+q){return -1}
    for i in 0..n{row:=input[2+i];if (n<64&&(row<0||(u64(row)>>n)!=0))||has_edge(row,i){return -1};for j in i+1..n{if has_edge(row,j)!=has_edge(input[2+j],i){return -1}}}
    mut remaining:=[max_n]int{};mut sample:=[max_q]int{};for i in 0..n{remaining[i]=i}
    for i in 0..q{draw:=input[2+n+i];if draw<0||draw>=i64(n-i){return -1};selected:=i+int(draw);temp:=remaining[i];remaining[i]=remaining[selected];remaining[selected]=temp;sample[i]=remaining[i]}
    mut adjacent:=[max_q][max_q]bool{};for i in 0..q{for j in i+1..q{edge:=has_edge(input[2+sample[i]],sample[j]);adjacent[i][j]=edge;adjacent[j][i]=edge}}
    mut color:=[max_q]int{};for i in 0..q{color[i]=-1};mut accepted:=i64(1)
    for start in 0..q{if color[start]!=-1{continue};mut queue:=[max_q]int{};mut head:=0;mut tail:=0;queue[tail]=start;tail++;color[start]=0;for head<tail{vertex:=queue[head];head++;for neighbor in 0..q{if !adjacent[vertex][neighbor]{continue};if color[neighbor]==-1{color[neighbor]=color[vertex]^1;queue[tail]=neighbor;tail++}else if color[neighbor]==color[vertex]{accepted=0}}}}
    if output==nil||capacity<16{return -2};mut staged:=[16]u8{};put_i64(mut &staged[0],0,accepted);put_i64(mut &staged[0],8,i64(q*(q-1)/2));for i in 0..16{output[i]=staged[i]};return 16
}}
