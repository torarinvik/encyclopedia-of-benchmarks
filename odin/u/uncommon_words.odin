package uncommon_words
import "core:c"
uncommon_words :: proc "c" (v: [^]i64,n: c.size_t,out: [^]u8,cap: c.size_t)->i64 {
 if v==nil||n<1||n>1089||v[0]<0||v[0]>64 do return -1
 words:=[64][16]u8{};lens:=[64]int{};counts:=[64]int{};temp:=[1089]u8{};d,p:=0,1
 for _ in 0..<int(v[0]) {if p>=int(n)||v[p]<1||v[p]>16 do return -1;l:=int(v[p]);p+=1;if l>int(n)-p do return -1;for j in 0..<l{if v[p+j]<97||v[p+j]>122 do return -1};id:=0;for id<d{if lens[id]==l{j:=0;for j<l&&i64(words[id][j])==v[p+j]{j+=1};if j==l do break};id+=1};if id==d{lens[d]=l;for j in 0..<l{words[d][j]=u8(v[p+j])};d+=1};counts[id]+=1;p+=l}
 if p!=int(n) do return -1;at:=0;for id in 0..<d{if counts[id]==1{for j in 0..<lens[id]{temp[at+j]=words[id][j]};at+=lens[id];temp[at]=10;at+=1}};if at>0 do at-=1;temp[at]=0;at+=1;if out==nil||cap<c.size_t(at) do return -2;for i in 0..<at{out[i]=temp[i]};return i64(at)
}
