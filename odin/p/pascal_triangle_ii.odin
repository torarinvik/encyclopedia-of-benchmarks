package pascal_triangle_ii
import "core:c"
MAX_ROW :: 30
MODULUS :: 1000000007
@(export)
pascal_triangle_ii :: proc "c" (row:i64)->i64{if row<0||row>MAX_ROW do return -9223372036854775807-1;triangle:[31*31]i64;triangle[0]=1;for i:=1;i<=int(row);i+=1{triangle[i*31]=1;triangle[i*31+i]=1;for j:=1;j<i;j+=1{triangle[i*31+j]=triangle[(i-1)*31+j-1]+triangle[(i-1)*31+j]}};hash:=i64(0);for j:=0;j<=int(row);j+=1{hash=(hash*31+triangle[int(row)*31+j])%MODULUS};return hash}
