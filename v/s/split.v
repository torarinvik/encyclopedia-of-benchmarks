module split
const max_text=256
@[export:'split']
pub fn split(input &i64,length usize,mut output &u8,capacity usize)i64{
 if unsafe{input==nil}||length<2||length>259{return -1};unsafe{if input[0]<0||input[0]>max_text||input[1]<0||input[1]>127{return -1};n:=int(input[0]);if length!=usize(n+2){return -1};for i in 0..n{if input[i+2]<0||input[i+2]>127{return -1}};if n>0&&input[n+1]==input[1]{return -1};mut separators:=0;for i in 0..n{if input[i+2]==input[1]{separators++}};if n>0&&separators==0{return -1};count:=separators+1;required:=2+2*count+n-separators;if unsafe{output==nil}||capacity<usize(required){return -2};output[0]=u8(count);output[1]=u8(count>>8);mut pos:=2;mut start:=0;for i in 0..n+1{if i==n||input[i+2]==input[1]{field:=i-start;output[pos]=u8(field);output[pos+1]=u8(field>>8);pos+=2;for j in start..i{output[pos]=u8(input[j+2]);pos++};start=i+1}};return i64(required)}
}
