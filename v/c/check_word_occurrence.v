module check_word_occurrence
const max_input=1024
const max_entries=1025
fn ws(c u8)bool{return (c>=9&&c<=13)||c==32}
fn lower_ascii(c u8)u8{if c>='A'&&c<='Z'{return c+32};return c}
fn forbidden(text &u8,start int,n int)bool{
 names:=['constructor','tostring','tolocalestring','valueof','hasownproperty','isprototypeof','propertyisenumerable']
 for name in names{if n==name.len{mut i:=0;for i<n&&lower_ascii(unsafe{text[start+i]})==name[i]{i++};if i==n{return true}}};return false
}
fn put32(mut out &u8,mut pos int,value u32){mut bits:=value;for _ in 0..4{unsafe{out[pos]=u8(bits&255)};pos++;bits>>=8}}
@[export:'check_word_occurrence']
pub fn check_word_occurrence(input &i64,length usize,mut output &u8,capacity usize)i64{
 if unsafe{input==nil}||length<2{return -1}
 unsafe{
  if input[0]<0||input[0]>1||input[1]<0||input[1]>max_input||length!=usize(input[1])+2{return -1};n:=int(input[1]);mut text:=[max_input]u8{}
  for i in 0..n{v:=input[i+2];if v<0||v>127{return -1};c:=u8(v);if !((c>='A'&&c<='Z')||(c>='a'&&c<='z')||ws(c)){return -1};text[i]=if input[0]==1{lower_ascii(c)}else{c}}
  mut starts:=[max_entries]int{};mut lens:=[max_entries]int{};mut counts:=[max_entries]u32{};mut entries:=0;mut i:=0;mut start:=0
  for{if i==n||ws(text[i]){size:=i-start;if forbidden(mut text[0],start,size){return -1};mut j:=0;for j<entries{if lens[j]==size{mut q:=0;for q<size&&text[starts[j]+q]==text[start+q]{q++};if q==size{break}};j++};if j==entries{starts[j]=start;lens[j]=size;entries++};counts[j]++;if i==n{break};for i<n&&ws(text[i]){i++};start=i}else{i++}}
  mut need:=4;for j in 0..entries{need+=8+lens[j]};if capacity<usize(need)||output==nil{return -2};mut pos:=0;put32(mut output,mut pos,u32(entries));for j in 0..entries{put32(mut output,mut pos,u32(lens[j]));for q in 0..lens[j]{output[pos]=text[starts[j]+q];pos++};put32(mut output,mut pos,counts[j])};return i64(pos)
 }
}
