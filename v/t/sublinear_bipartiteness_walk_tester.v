module sublinear_bipartiteness_walk_tester
const max_n=16
const max_d=4
const max_edges=32
const max_t=4
const max_r=8
const max_l=8
const max_input=330

fn put_i64(mut output &u8,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[byte]=u8((bits>>(8*byte))&255)}}}

@[export:'sublinear_bipartiteness_walk_tester']
pub fn sublinear_bipartiteness_walk_tester(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{
    if input==nil||length<8||length>max_input||input[0]<1||input[0]>max_n||input[1]<3||input[1]>max_d||input[2]<0||input[2]>max_edges{return -1}
    n,d,m:=int(input[0]),int(input[1]),int(input[2]);if m>n*d/2{return -1};suffix:=3+2*m;if length<usize(suffix+4){return -1}
    if input[suffix]<1||input[suffix]>max_t||input[suffix+1]<1||input[suffix+1]>max_r||input[suffix+2]<1||input[suffix+2]>max_l{return -1}
    tc,walks,steps:=int(input[suffix]),int(input[suffix+1]),int(input[suffix+2]);if length!=usize(suffix+3+tc+tc*walks*steps){return -1}
    mut adjacent:=[max_n][max_n]bool{};mut neighbors:=[max_n][max_d]int{};mut degree:=[max_n]int{}
    for e in 0..m{a0,b0:=input[3+2*e],input[4+2*e];if a0<0||b0<0||a0>=i64(n)||b0>=i64(n)||a0>=b0{return -1};a,b:=int(a0),int(b0);if adjacent[a][b]||degree[a]>=d||degree[b]>=d{return -1};adjacent[a][b]=true;adjacent[b][a]=true;mut at:=degree[a];degree[a]++;for at>0&&neighbors[a][at-1]>b{neighbors[a][at]=neighbors[a][at-1];at--};neighbors[a][at]=b;at=degree[b];degree[b]++;for at>0&&neighbors[b][at-1]>a{neighbors[b][at]=neighbors[b][at-1];at--};neighbors[b][at]=a}
    starts_at:=suffix+3;draws_at:=starts_at+tc;for t in 0..tc{if input[starts_at+t]<0||input[starts_at+t]>=i64(n){return -1}};draw_count:=tc*walks*steps;for i in 0..draw_count{if input[draws_at+i]<0||input[draws_at+i]>=i64(2*d){return -1}}
    mut accepted:=true;mut draw:=0;for t in 0..tc{if !accepted{break};mut seen:=[max_n][2]bool{};start:=int(input[starts_at+t]);seen[start][0]=true;for _ in 0..walks{if !accepted{break};mut vertex:=start;mut parity:=0;for _ in 0..steps{choice:=int(input[draws_at+draw]);draw++;if choice<degree[vertex]{vertex=neighbors[vertex][choice];parity^=1};seen[vertex][parity]=true;if seen[vertex][1-parity]{accepted=false;break}}}}
    if output==nil||capacity<8{return -2};mut verdict:=i64(0);if accepted{verdict=1};mut staged:=[8]u8{};put_i64(mut &staged[0],verdict);for i in 0..8{output[i]=staged[i]};return 8
}}
