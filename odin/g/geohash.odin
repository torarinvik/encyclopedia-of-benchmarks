package geohash
import "core:c"
ALPHABET :: "0123456789bcdefghjkmnpqrstuvwxyz"
@(export)
geohash :: proc "c" (v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n!=2 do return -1
 if v[0]<-90000000||v[0]>90000000||v[1]<-180000000||v[1]>180000000 do return -1
 lat:=f64(v[0])/1_000_000.0;lon:=f64(v[1])/1_000_000.0;latlo:= -90.0;lathi:=90.0;lonlo:= -180.0;lonhi:=180.0;bit:=0;value:=0;islon:=true;b:[12]u8;p:=0
 for p<12{mid:f64;if islon{mid=(lonlo+lonhi)/2;if lon>mid{value|=1<<(4-bit);lonlo=mid}else{lonhi=mid}}else{mid=(latlo+lathi)/2;if lat>mid{value|=1<<(4-bit);latlo=mid}else{lathi=mid}};islon=!islon;if bit<4{bit+=1}else{b[p]=ALPHABET[value];p+=1;bit=0;value=0}}
 if out==nil||cap<12 do return -2
 for i:=0;i<12;i+=1{out[i]=b[i]}
 return 12
}
