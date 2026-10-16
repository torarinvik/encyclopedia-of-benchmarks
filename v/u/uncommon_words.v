const max_words=64
const max_word_length=16
@[export:'uncommon_words']
pub fn uncommon_words(values &i64,length usize,mut output &u8,capacity usize)i64{
 if unsafe{values==nil}||length<1||length>1089||unsafe{values[0]<0||values[0]>64}{return -1}
 mut words:=[max_words][max_word_length]u8{};mut lens:=[max_words]int{};mut counts:=[max_words]int{};mut distinct:=0;mut pos:=1
 for _ in 0..int(unsafe{values[0]}){if pos>=int(length)||unsafe{values[pos]<1||values[pos]>16}{return -1};size:=int(unsafe{values[pos]});pos++;if size>int(length)-pos{return -1};for j in 0..size{if unsafe{values[pos+j]<97||values[pos+j]>122}{return -1}};mut id:=0;for id<distinct{if lens[id]==size{mut j:=0;for j<size&&i64(words[id][j])==unsafe{values[pos+j]}{j++};if j==size{break}};id++};if id==distinct{lens[id]=size;for j in 0..size{words[id][j]=u8(unsafe{values[pos+j]})};distinct++};counts[id]++;pos+=size}
 if pos!=int(length){return -1};mut temp:=[1089]u8{};mut at:=0;for id in 0..distinct{if counts[id]==1{for j in 0..lens[id]{temp[at+j]=words[id][j]};at+=lens[id];temp[at]=10;at++}};if at>0{at--};temp[at]=0;at++;if unsafe{output==nil}||capacity<at{return -2};for i in 0..at{unsafe{output[i]=temp[i]}};return i64(at)
}
