package split
import "core:c"
@(export)
split :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2||length>259 do return -1
 if input[0]<0||input[0]>256||input[1]<0||input[1]>127 do return -1
 n:=int(input[0]);if length!=c.size_t(n+2) do return -1
 for i:=0;i<n;i+=1{if input[i+2]<0||input[i+2]>127 do return -1}
 if n>0&&input[n+1]==input[1] do return -1
 separators:=0;for i:=0;i<n;i+=1{if input[i+2]==input[1] do separators+=1};if n>0&&separators==0 do return -1;count:=separators+1;required:=2+2*count+n-separators
 if output==nil||capacity<c.size_t(required) do return -2
 output[0]=u8(count);output[1]=u8(count>>8);pos:=2;start:=0;for i:=0;i<=n;i+=1{if i==n||input[i+2]==input[1]{field:=i-start;output[pos]=u8(field);output[pos+1]=u8(field>>8);pos+=2;for j:=start;j<i;j+=1{output[pos]=u8(input[j+2]);pos+=1};start=i+1}};return i64(required)
}
