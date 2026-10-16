module main
@[export: 'simple_keyword_cypher_decipher']
pub fn simple_keyword_cypher_decipher(v &i64,n usize,mut output &u8,capacity usize) i64 {
 unsafe { if v==nil||n<2||n>323{return -1} kl:=v[0];ml:=v[1];if kl<0||kl>64||ml<0||ml>256||n!=usize(2+kl+ml){return -1}
 mut key:=[26]u8{};mut count:=0;for i in 0..int(kl){x:=v[2+i];if !((x>=65&&x<=90)||(x>=97&&x<=122)){return -1} c:=u8(if x>=97{x-32}else{x});mut found:=false;for j in 0..count{if key[j]==c{found=true}}if !found{key[count]=c;count++}}
 mut map:=[26]u8{};mut k:=0;for i in 0..count{map[k]=key[i];k++}for x in 65..91{mut found:=false;for j in 0..count{if key[j]==u8(x){found=true}}if !found{map[k]=u8(x);k++}}
 mut result:=[256]u8{};for i in 0..int(ml){x:=v[2+int(kl)+i];if x<0||x>127{return -1}c:=u8(if x>=97&&x<=122{x-32}else{x});if c>=65&&c<=90{mut j:=0;for j<26&&map[j]!=c{j++}if j==26{return -1}result[i]=u8(65 + j)}else{result[i]=c}}
 if output==nil||capacity<usize(ml){return -2}for i in 0..int(ml){output[i]=result[i]}return ml } }
