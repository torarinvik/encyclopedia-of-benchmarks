package percentage
import "core:c"
@(export)
percentage :: proc "c" (v:[^]i64,n:c.size_t)->i64{
 if v==nil||n!=3||v[0]<1||v[0]>100000||v[1]<1||v[1]>100000||v[2]<1||v[2]>4 do return -1
 scale:=i64(1);for i:=i64(0);i<v[2];i+=1{scale*=10};product:=v[0]*v[1]*scale;if product<100 do return -1;return product/100
}
