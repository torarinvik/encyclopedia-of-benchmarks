module range_minimum_query
const max_n = 64
fn put_i64_le(mut output &u8, offset int, value i64) { mut bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8(bits&255)};bits>>=8} }
@[export: 'range_minimum_query']
pub fn range_minimum_query(input &i64,length usize,mut output &u8,capacity usize) i64 {
    if unsafe{input==nil}||length<4{return -1};if input[0]<1||input[0]>64{return -1};n:=int(input[0]);qp:=1+n
    if length<=qp||input[qp]<1||input[qp]>64{return -1};q:=int(input[qp]);if length!=qp+1+2*q{return -1}
    unsafe{mut values:=[max_n]i64{};for i in 0..n{values[i]=input[1+i];if values[i]<-1000||values[i]>1000{return -1}}
        if capacity<q*8||(q>0&&output==nil){return -2}
        mut table:=[7][max_n]int{};for i in 0..n{table[0][i]=i}
        for k:=1;(1<<k)<=n;k++{width:=1<<k;half:=width>>1;for i:=0;i+width<=n;i++{a:=table[k-1][i];b:=table[k-1][i+half];table[k][i]=if values[a]<values[b]{a}else{b}}}
        invalid:=i64(-9223372036854775807)-1
        for j in 0..q{left:=input[qp+1+2*j];right:=input[qp+2+2*j];mut answer:=invalid
            if left>=0&&right>left&&right<=i64(n){l:=int(left);r:=int(right);span:=r-l;mut level:=0;for (1<<(level+1))<=span{level++};width:=1<<level;a:=table[level][l];b:=table[level][r-width];answer=if values[a]<values[b]{values[a]}else{values[b]}}
            put_i64_le(mut output,j*8,answer)}
        return i64(q*8)
    }
}
