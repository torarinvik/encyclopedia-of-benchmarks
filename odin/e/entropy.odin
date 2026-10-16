package entropy
import "core:c"
import "core:math"
MAX_TEXT :: 512
ALPHABET_SIZE :: 128
round_even :: proc(value: f64) -> int { lower:=math.floor_f64(value); fraction:=value-lower; if fraction<0.5{return int(lower)};if fraction>0.5{return int(lower+1.0)};n:=int(lower);if n%2==0{return n};return n+1 }
emit_line :: proc(out:[^]u8,pos_input:int,value_input:int)->int {pos:=pos_input;value:=value_input;if value<0{out[pos]='-';pos+=1;value=-value};if value>=10{out[pos]=u8('0'+value/10);pos+=1};out[pos]=u8('0'+value%10);pos+=1;out[pos]='.';pos+=1;out[pos]='0';pos+=1;out[pos]='\n';pos+=1;return pos}
@(export)
entropy :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<2||length>c.size_t(MAX_TEXT+1) do return -1
 n:=input[0];if n<1||n>MAX_TEXT||length!=c.size_t(n+1) do return -1
 singles:[ALPHABET_SIZE]i64; pairs:[ALPHABET_SIZE*ALPHABET_SIZE]i64
 for i:=0;i<int(n);i+=1 {ch:=input[i+1];if ch<0||ch>=ALPHABET_SIZE do return -1;singles[int(ch)]+=1}
 pairs[32*ALPHABET_SIZE+int(input[1])]+=1
 for i:=0;i<int(n)-1;i+=1 {pairs[int(input[i+1])*ALPHABET_SIZE+int(input[i+2])]+=1}
 alpha:=[27]int{32,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122};sum_single,sum_pair:=f64(0),f64(0)
 for a in alpha {count:=singles[a];if count>0 {p:=f64(count)/f64(n);sum_single+=p*math.log2_f64(p)}}
 for a in alpha {for b in alpha {count:=pairs[a*ALPHABET_SIZE+b];if count>0 {p:=f64(count)/f64(n);sum_pair+=p*math.log2_f64(p)}}}
 temp:[32]u8;written:=emit_line(&temp[0],0,round_even(-sum_single));written=emit_line(&temp[0],written,round_even(-sum_pair));written=emit_line(&temp[0],written,round_even((-sum_pair)-(-sum_single)));if output==nil||capacity<c.size_t(written) do return -2
 for i:=0;i<written;i+=1 {output[i]=temp[i]};return i64(written)
}
