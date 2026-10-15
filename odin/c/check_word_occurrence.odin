package check_word_occurrence
import "core:c"
MAX_INPUT :: 1024
MAX_ENTRIES :: 1025
ws :: proc(c:u8)->bool{return (c>=9&&c<=13)||c==32}
lower_ascii :: proc(c:u8)->u8{if c>='A'&&c<='Z' do return c+32;return c}
forbidden :: proc(text:[^]u8,start,n:usize)->bool{
 names:=[7]string{"constructor","tostring","tolocalestring","valueof","hasownproperty","isprototypeof","propertyisenumerable"}
 for x in 0..<7{if n==usize(len(names[x])){i:usize=0;for i<n&&lower_ascii(text[start+i])==names[x][i]{i+=1};if i==n do return true}};return false
}
put32 :: proc "contextless" (out:[^]u8,pos:^usize,value:u32){bits:=value;for i:usize=0;i<4;i+=1{out[pos^]=u8(bits&255);pos^+=1;bits>>=8}}
@(export)
check_word_occurrence :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2||input[0]<0||input[0]>1||input[1]<0||input[1]>MAX_INPUT||length!=usize(input[1])+2 do return -1
 n:=usize(input[1]);text:[MAX_INPUT]u8
 for i:usize=0;i<n;i+=1{v:=input[i+2];if v<0||v>127 do return -1;c:=u8(v);if !((c>='A'&&c<='Z')||(c>='a'&&c<='z')||ws(c)) do return -1;text[i]=if input[0]==1{lower_ascii(c)}else{c}}
 starts:[MAX_ENTRIES]usize; lens:[MAX_ENTRIES]usize; counts:[MAX_ENTRIES]u32; entries:usize=0; i:usize=0; start:usize=0
 for {if i==n||ws(text[i]){size:=i-start;if forbidden(&text[0],start,size) do return -1;j:usize=0;for j<entries{if lens[j]==size{q:usize=0;for q<size&&text[starts[j]+q]==text[start+q]{q+=1};if q==size do break};j+=1};if j==entries{starts[j]=start;lens[j]=size;entries+=1};counts[j]+=1;if i==n do break;for i<n&&ws(text[i]){i+=1};start=i}else{i+=1}}
 need:usize=4;for j:usize=0;j<entries;j+=1{need+=8+lens[j]};if capacity<need||output==nil do return -2
 pos:usize=0;put32(output,&pos,u32(entries));for j:usize=0;j<entries;j+=1{put32(output,&pos,u32(lens[j]));for q:usize=0;q<lens[j];q+=1{output[pos]=text[starts[j]+q];pos+=1};put32(output,&pos,counts[j])};return i64(pos)
}
