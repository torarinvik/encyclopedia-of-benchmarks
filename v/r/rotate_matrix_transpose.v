module main
const max_cells=1024
fn store_le(mut output &u8,offset int,value i64){bits:=u64(value);for b in 0..8{output[offset+b]=u8((bits>>(b*8))&255)}}
@[export: 'rotate_matrix_transpose']
pub fn rotate_matrix_transpose(v &i64,n usize,mut output &u8,capacity usize) i64{unsafe{if v==nil||n<2||n>1027{return -1}r:=v[0];c:=v[1];if r<1||r>32||c<1||c>32||n!=usize(2+r*c){return -1}rows:=int(r);cols:=int(c);mut matrix:=[max_cells]i64{};mut result:=[max_cells]i64{};for i in 0..rows*cols{matrix[i]=v[2+i]}orows:=int(cols);ocols:=int(rows);for i in 0..rows{for j in 0..cols{rr:=int(j);cc:=int(i);result[rr*ocols+cc]=matrix[i*cols+j]}}bytes:=8*(2+orows*ocols);if output==nil||capacity<usize(bytes){return -2}store_le(mut output,0,i64(orows));store_le(mut output,8,i64(ocols));for i in 0..orows*ocols{store_le(mut output,16+8*i,result[i])}return i64(bytes)}}
