const alphabet="0123456789bcdefghjkmnpqrstuvwxyz";
export fn geohash(v:[*c]const i64,n:usize,out:[*c]u8,cap:usize)i64{
 if(v==null or n!=2)return -1;if(v[0]<-90000000 or v[0]>90000000 or v[1]<-180000000 or v[1]>180000000)return -1;
 const lat=@as(f64,@floatFromInt(v[0]))/1_000_000.0;const lon=@as(f64,@floatFromInt(v[1]))/1_000_000.0;var latlo:f64= -90;var lathi:f64=90;var lonlo:f64= -180;var lonhi:f64=180;var bit:usize=0;var value:u8=0;var islon=true;var b:[12]u8=undefined;var p:usize=0;
 while(p<12){var mid:f64=0;if(islon){mid=(lonlo+lonhi)/2;if(lon>mid){value|=@as(u8,1)<<@intCast(4-bit);lonlo=mid}else{lonhi=mid}}else{mid=(latlo+lathi)/2;if(lat>mid){value|=@as(u8,1)<<@intCast(4-bit);latlo=mid}else{lathi=mid}}islon=!islon;if(bit<4){bit+=1}else{b[p]=alphabet[value];p+=1;bit=0;value=0}}
 if(out==null or cap<12)return -2;@memcpy(out[0..12],b[0..12]);return 12;
}
