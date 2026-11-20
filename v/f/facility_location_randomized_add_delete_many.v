module facility_location_randomized_add_delete_many
import core.c

const max_n = 5
const max_f = 5
const max_q = 8
const max_p = 10
const max_parseable = 128

fn put(out &u8, at int, value i64) { bits := u64(value); for i in 0 .. 8 { out[at+i] = u8((bits >> (8*i)) & 255) } }
fn state_cost(n int, f int, d [][]i64, demand []i64, assignment []i64, fee []i64, mask u32) i64 {
    mut total := i64(0)
    for s in 0 .. f { if mask & (u32(1) << s) != 0 { total += fee[s] } }
    for j in 0 .. n { total += demand[j] * d[j][n+int(assignment[j])] }
    return total
}

@[export: 'facility_location_randomized_add_delete_many']
pub fn facility_location_randomized_add_delete_many(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 12 || length > max_parseable { return -1 }
        n0, f0, q0, raw := input[0], input[1], input[2], input[3]
        if n0 < 1 || n0 > 5 || f0 < 1 || f0 > 5 || q0 < 1 || q0 > 8 || raw <= 0 || u64(raw) >= (u64(1) << int(f0)) { return -1 }
        n, f, q := int(n0), int(f0), int(q0)
        p := n+f
        if length != usize(4+2*n+p*p+f+q) { return -1 }
        mut mask := u32(raw)
        mut assignment := []i64{len: n, init: 0}
        mut demand := []i64{len: n, init: 0}
        mut d := [][]i64{len: p, init: []i64{len: p, init: 0}}
        mut fee := []i64{len: f, init: 0}
        mut tape := []i64{len: q, init: 0}
        mut pos := 4
        for j in 0 .. n { assignment[j]=input[pos]; pos++; if assignment[j]<0||assignment[j]>=f0||mask&(u32(1)<<int(assignment[j]))==0{return -1} }
        for j in 0 .. n { demand[j]=input[pos];pos++;if demand[j]<1||demand[j]>10{return -1} }
        for i in 0 .. p { for j in 0 .. p { value:=input[pos];pos++;if value<0||value>1000{return -1};d[i][j]=value } }
        for i in 0 .. p { if d[i][i]!=0{return -1};for j in 0 .. p { if i!=j&&d[i][j]==0{return -1};if d[i][j]!=d[j][i]{return -1};for k in 0 .. p {if d[i][j]>d[i][k]+d[k][j]{return -1}} } }
        for s in 0 .. f {fee[s]=input[pos];pos++;if fee[s]<0||fee[s]>1000{return -1}}
        for t in 0 .. q {tape[t]=input[pos];pos++;if tape[t]<0||tape[t]>=f0{return -1}}
        mut costs:=[]i64{len:q,init:0};mut accepted:=[]i64{len:q,init:0};mut current:=state_cost(n,f,d,demand,assignment,fee,mask);mut count:=i64(0)
        for step in 0 .. q {
            candidate:=int(tape[step]);bit:=u32(1)<<candidate;mut did:=i64(0)
            if mask&bit==0 {
                mut closer:=[]bool{len:n,init:false};mut gain:=-fee[candidate]
                for j in 0 .. n {old:=int(assignment[j]);if d[j][n+candidate]<d[j][n+old]{closer[j]=true;gain+=demand[j]*(d[j][n+old]-d[j][n+candidate])}}
                mut drop:=u32(0)
                for s in 0 .. f {if mask&(u32(1)<<s)!=0{mut cg:=fee[s];for j in 0 .. n{if int(assignment[j])==s&&!closer[j]{cg+=demand[j]*(d[j][n+s]-d[j][n+candidate])}};if cg>0{drop|=u32(1)<<s;gain+=cg}}}
                if gain>0 {mask=(mask|bit)&~drop;for j in 0 .. n{if closer[j]||drop&(u32(1)<<int(assignment[j]))!=0{assignment[j]=i64(candidate)}};current=state_cost(n,f,d,demand,assignment,fee,mask);did=1;count++}
            }
            costs[step]=current;accepted[step]=did
        }
        bytes:=8*(2*q+3+n);if output==nil||capacity<bytes{return -2}
        pos=0;for t in 0 .. q{put(output,pos,costs[t]);pos+=8};for t in 0 .. q{put(output,pos,accepted[t]);pos+=8};put(output,pos,current);pos+=8;put(output,pos,i64(mask));pos+=8;for j in 0 .. n{put(output,pos,assignment[j]);pos+=8};put(output,pos,count);pos+=8
        return i64(pos)
    }
}
