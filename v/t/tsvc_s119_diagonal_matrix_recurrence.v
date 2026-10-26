// Clean-room TSVC s119 profile; see package rights note.
const max_side=8
const max_cells=64
const max_input_length=130
fn put64(out &u8,pos int,value i64){mut bits:=u64(value);for j in 0..8{unsafe{out[pos+j]=u8(bits&255)};bits>>=8}}
@[export:'tsvc_s119_diagonal_matrix_recurrence']
pub fn tsvc_s119_diagonal_matrix_recurrence(input &i64,length usize,output &u8,capacity usize)i64{
 if unsafe{input==nil}||length<10||length>max_input_length{return -1}
 sr:=unsafe{input[0]};pr:=unsafe{input[1]};if sr<2||sr>max_side||pr<1||pr>4{return -1};n:=int(sr);passes:=int(pr);cells:=n*n;if int(length)!=2+2*cells{return -1}
 mut a:=[max_cells]i64{};mut b:=[max_cells]i64{}
 for i in 0..cells{av:=unsafe{input[2+i]};bv:=unsafe{input[2+cells+i]};if av< -2||av>2||bv< -2||bv>2{return -1};a[i]=av;b[i]=bv}
 bytes:=8*cells;if unsafe{output==nil}||capacity<usize(bytes){return -2};for _ in 0..passes{for i in 1..n{for j in 1..n{a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j]}}};for i in 0..cells{put64(output,8*i,a[i])};return i64(cells)
}
