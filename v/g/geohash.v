module geohash
@[export: 'geohash']
pub fn geohash(v &i64,n usize,out &u8,cap usize)i64{
 if isnil(v)||n!=2{return -1}
 unsafe{
  if v[0]< -90000000||v[0]>90000000||v[1]< -180000000||v[1]>180000000{return -1}
  alphabet := "0123456789bcdefghjkmnpqrstuvwxyz"
  lat:=f64(v[0])/1000000.0;lon:=f64(v[1])/1000000.0;mut latlo:= -90.0;mut lathi:=90.0;mut lonlo:= -180.0;mut lonhi:=180.0;mut bit:=0;mut value:=0;mut islon:=true;mut b:=[]u8{len:12};mut p:=0
  for p<12{mut mid:=0.0;if islon{mid=(lonlo+lonhi)/2;if lon>mid{value|=1<<(4-bit);lonlo=mid}else{lonhi=mid}}else{mid=(latlo+lathi)/2;if lat>mid{value|=1<<(4-bit);latlo=mid}else{lathi=mid}};islon=!islon;if bit<4{bit++}else{b[p]=alphabet[value];p++;bit=0;value=0}}
  if isnil(out)||cap<12{return -2};for i in 0..12{out[i]=b[i]};return 12
 }
}
