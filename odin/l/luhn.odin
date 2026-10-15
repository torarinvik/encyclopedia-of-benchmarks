package luhn
import "core:c"
@(export)
luhn_validate :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
 if input==nil||length<1 do return -1
 n:=input[0];if n<2||n>64||n%2!=0||length!=c.size_t(n+1) do return -1
 sum:i64=0
 for i:=i64(0);i<n;i+=1 {digit:=input[i+1];if digit<0||digit>9 do return -1;if i%2==0 {digit*=2;if digit>9 {digit-=9}};sum+=digit}
 if sum%10==0{return 1};return 0
}
