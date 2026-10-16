package linked_deque
import "core:c"
@(export)
linked_deque :: proc "c" (v:[^]i64,n:c.size_t)->i64{
 if v==nil||n<2||n>20||n%2!=0{return -1};q:=[40]i64{};h:=c.size_t(16);t:=c.size_t(16);out:=i64(0);place:=i64(1)
 for p:=c.size_t(0);p<n;p+=2{op:=v[p];a:=v[p+1];if op<0||op>6{return -1};if op<2{if a < -15||a>15{return -1};if op==0{h-=1;q[h]=a}else{q[t]=a;t+=1};continue};if a!=0{return -1};d:=i64(0);if op==2{if h<t{d=q[h]+16;h+=1}}else if op==3{if h<t{t-=1;d=q[t]+16}}else if op==4{if h<t{d=q[h]+16}}else if op==5{if h<t{d=q[t-1]+16}}else{if h==t{d=1}else{d=2}};out+=d*place;place*=32}
 return out
}
