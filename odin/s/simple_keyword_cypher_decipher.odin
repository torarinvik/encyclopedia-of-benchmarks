package simple_keyword_cypher_decipher
import "core:c"
@(export)
simple_keyword_cypher_decipher :: proc "c" (v: [^]i64,n:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if v==nil||n<2||n>323 do return -1
 kl,ml:=v[0],v[1];if kl<0||kl>64||ml<0||ml>256||n!=2+c.size_t(kl+ml) do return -1
 key:[26]u8={};count:=0
 for i in 0..<int(kl){x:=v[2+i];if !((x>=65&&x<=90)||(x>=97&&x<=122)) do return -1;c:=u8(if x>=97 then x-32 else x);found:=false;for j in 0..<count{if key[j]==c do found=true};if !found{key[count]=c;count+=1}}
 map:[26]u8={};k:=0;for i in 0..<count{map[k]=key[i];k+=1};for x in 65..<91{found:=false;for j in 0..<count{if key[j]==u8(x) do found=true};if !found{map[k]=u8(x);k+=1}}
 result:[256]u8={};for i in 0..<int(ml){x:=v[2+int(kl)+i];if x<0||x>127 do return -1;c:=u8(if x>=97&&x<=122 then x-32 else x);if c>=65&&c<=90{j:=0;for j<26&&map[j]!=c{j+=1};if j==26 do return -1;result[i]=u8(65+j)}else{result[i]=c}}
 if output==nil||capacity<c.size_t(ml) do return -2;for i in 0..<int(ml){output[i]=result[i]};return ml
}
