package parse_date
import "core:c"
@(export)
parse_date :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<9||n>11||v[0]<8||v[0]>10||n!=c.size_t(v[0]+1) do return -1;length:=int(v[0]);s1:=0;s2:=0;for i:=1;i<=length;i+=1{x:=v[i];if x<0||x>127 do return -1;if x==47{if s1==0 do s1=i else if s2==0 do s2=i else return -1}};if s1<2||s1>3||s2<=s1+1||s2-s1<2||s2-s1>3||length-s2!=4 do return -1;d:=i64(0);m:=i64(0);y:=i64(0);for i:=1;i<s1;i+=1{x:=v[i];if x<48||x>57 do return -1;d=d*10+x-48};for i:=s1+1;i<s2;i+=1{x:=v[i];if x<48||x>57 do return -1;m=m*10+x-48};for i:=s2+1;i<=length;i+=1{x:=v[i];if x<48||x>57 do return -1;y=y*10+x-48};if m<1||m>12 do return -1;days:=[12]i64{31,28,31,30,31,30,31,31,30,31,30,31};if m==2&&y%4==0&&(y%100!=0||y%400==0) do days[1]=29;if d<1||d>days[int(m-1)] do return -1;return y*10000+m*100+d}

