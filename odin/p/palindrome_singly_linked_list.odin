package palindrome_singly_linked_list
import "core:c"
@(export)
palindrome_singly_linked_list :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>65||v[0]<0||v[0]>64||n!=c.size_t(v[0]+1) do return -1;length:=int(v[0]);for i:=1;i<int(n);i+=1{if v[i]<-2_147_483_648||v[i]>2_147_483_647 do return -1};slow:=0;fast:=0;for fast+1<length{slow+=1;fast+=2};suffix:=length-slow;for i:=0;i<suffix;i+=1{if v[i+1]!=v[length-i] do return 0};return 1}

