package word_occurrence
import "core:c"

MAX_INPUT :: 1024
MAX_ENTRIES :: 512
ws :: proc "contextless" (c:u8)->bool{return (c>=9&&c<=13)||(c>=28&&c<=32)}
put32 :: proc "contextless" (output:[^]u8,pos:^usize,value:u32){bits:=value;for i:usize=0;i<4;i+=1{output[pos^]=u8(bits&255);pos^+=1;bits>>=8}}
@(export,link_name="word_occurrence")
word_occurrence :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<1||length>1025 do return -1
 n_arg:=input[0];if n_arg<0||n_arg>1024||length!=usize(n_arg)+1 do return -1
 n:=usize(n_arg);text:[MAX_INPUT]u8
 for i:usize=0;i<n;i+=1{value:=input[i+1];if value<0||value>127 do return -1;text[i]=u8(value)}
 starts:[MAX_ENTRIES]usize;lens:[MAX_ENTRIES]usize;counts:[MAX_ENTRIES]u32;entries:usize=0;i:usize=0
 for i<n{for i<n&&ws(text[i]){i+=1};if i==n do break;start:=i;for i<n&&!ws(text[i]){i+=1};token_len:=i-start;j:usize=0;for j<entries{if lens[j]==token_len{q:usize=0;for q<token_len&&text[starts[j]+q]==text[start+q]{q+=1};if q==token_len do break};j+=1};if j==entries{if entries>=MAX_ENTRIES do return -1;starts[j]=start;lens[j]=token_len;counts[j]=0;entries+=1};counts[j]+=1}
 need:usize=4;for j:usize=0;j<entries;j+=1{need+=8+lens[j]};if output==nil||capacity<need do return -2
 pos:usize=0;put32(output,&pos,u32(entries));for j:usize=0;j<entries;j+=1{put32(output,&pos,u32(lens[j]));for q:usize=0;q<lens[j];q+=1{output[pos]=text[starts[j]+q];pos+=1};put32(output,&pos,counts[j])};return i64(pos)
}
main :: proc() {}
