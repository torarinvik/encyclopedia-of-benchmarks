module problem59
const max_cipher=4096
const key_count=17576
fn allowed(value int) bool { return (value>=9&&value<=13)||(value>=32&&value<=126) }
fn word_length(id int) int { return [3,2,2,2,3,2,4,4][id] }
fn word_char(id int,j int) u8 { words:=[8]string{'the','be','to','of','and','in','that','have'};return words[id][j] }
fn lower_ascii(value u8) u8 { return if value>=65&&value<=90 {value+32} else {value} }
fn contains_word(input &i64,length usize,keys []u8,index int,id int) bool {
 width:=word_length(id);if length<usize(width){return false}
 for start in 0..(int(length)-width+1){mut matched:=true;for j in 0..width{pos:=start+j;ch:=lower_ascii(u8(unsafe{input[pos]})^keys[index*3+pos%3]);if ch!=word_char(id,j){matched=false;break}}if matched{return true}}return false
}
@[export:'problem59']
pub fn problem59(input &i64,length usize) i64 {
 if unsafe{input==nil}||length==0||length>max_cipher{return -1}
 for i in 0..int(length){v:=unsafe{input[i]};if v<0||v>255{return -1}}
 mut keys:=[key_count*3]u8{};mut count:=0
 for a in 97..123{for b in 97..123{for c in 97..123{mut valid:=true;for i in 0..int(length){v:=unsafe{input[i]};k:=if i%3==0{a}else if i%3==1{b}else{c};if !allowed(int(v)^k){valid=false;break}}if valid{keys[count*3]=u8(a);keys[count*3+1]=u8(b);keys[count*3+2]=u8(c);count++}}}}
 for id in 0..8{mut kept:=0;for i in 0..count{if contains_word(input,length,keys,i,id){if kept!=i{keys[kept*3]=keys[i*3];keys[kept*3+1]=keys[i*3+1];keys[kept*3+2]=keys[i*3+2]}kept++}}count=kept;if count==1{break}}
 if count==0{return -1};mut sum:=i64(0);for i in 0..int(length){sum+=unsafe{input[i]}^i64(keys[i%3])};return sum
}
