package conway
import "core:c"
MAX_TEXT_LENGTH :: 128
decimal_digits :: proc(value_input: int) -> int { value:=value_input; digits:=1; for value>=10 { value/=10; digits+=1 }; return digits }

@(export)
conway :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
 if input == nil || length < 2 || length > c.size_t(MAX_TEXT_LENGTH+1) do return -1
 n:=input[0]; if n<1 || n>MAX_TEXT_LENGTH || length!=c.size_t(n+1) do return -1
 for i:=0;i<int(n);i+=1 { if input[i+1]<0 || input[i+1]>127 do return -1 }
 needed:=0; i:=0
 for i<int(n) { j:=i+1; for j<int(n) && (input[j]==input[j+1] || input[j]==10 || input[j]==13) { j+=1 }; needed+=decimal_digits(j-i)+1; i=j }
 if output==nil || capacity<c.size_t(needed) do return -2
 pos:=0; i=0
 for i<int(n) { j:=i+1; for j<int(n) && (input[j]==input[j+1] || input[j]==10 || input[j]==13) { j+=1 }; run:=j-i; start:=pos
  for { output[pos]=u8(48+run%10);pos+=1;run/=10;if run==0{break} }
  left,right:=start,pos-1;for left<right { tmp:=output[left];output[left]=output[right];output[right]=tmp;left+=1;right-=1 }
  output[pos]=u8(input[i+1]);pos+=1;i=j
 }
 return i64(pos)
}
