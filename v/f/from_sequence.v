module main
const max_nodes = 128
const max_output = 3589
fn append_i64(mut buffer []u8, start int, value i64) int {
 mut digits := []u8{len:20}; mut length:=0
 mut magnitude:=if value<0 {u64(-(value+1))+u64(1)} else {u64(value)}
 for { digits[length]=u8(`0`)+u8(magnitude%10);length++;magnitude/=10;if magnitude==0{break} }
 mut p:=start;buffer[p]=`<`;p++;if value<0{buffer[p]=`-`;p++}
 for length>0 {length--;buffer[p]=digits[length];p++}
 buffer[p]=`>`;p++;for ch in ' ---> ' {buffer[p]=u8(ch);p++};return p
}
@[export: 'from_sequence']
pub fn from_sequence(v &i64,n usize,out &u8,cap usize)i64 {
 if isnil(v)||n<2||n>max_nodes+1{return -1};count:=unsafe{v[0]};if count<1||count>max_nodes||n!=usize(count+1){return -1}
 mut buffer:=[]u8{len:max_output};mut p:=0
 for i in 0..count {p=append_i64(mut buffer,p,unsafe{v[i+1]})}
 for ch in '<END>' {buffer[p]=u8(ch);p++}
 if isnil(out)||cap<p{return -2};unsafe{for i in 0..p{out[i]=buffer[i]}};return i64(p)
}
