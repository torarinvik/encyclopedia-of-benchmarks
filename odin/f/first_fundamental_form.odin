package first_fundamental_form
feed :: proc "contextless" (h0:u64,x:i64)->u64{h:=h0;u:=transmute(u64)x;for b:=u32(0);b<8;b+=1{h=(h~((u>>(8*b))&255))*0x100000001b3};return h}
product :: proc "contextless" (a,b:[3]i64,o:^[6]i64){o[0]+=a[0]*b[0];o[1]+=a[0]*b[1]+a[1]*b[0];o[2]+=a[0]*b[2]+a[2]*b[0];o[3]+=a[1]*b[1];o[4]+=a[1]*b[2]+a[2]*b[1];o[5]+=a[2]*b[2]}
@(export)
first_fundamental_form :: proc "c" (v:[^]i64,n:u64)->i64{
 if v==nil||n!=18 do return -1;for i:=u64(0);i<18;i+=1{if v[i]< -100||v[i]>100 do return -1}
 ru:[3][3]i64;rv:[3][3]i64;e:[6]i64;f:[6]i64;g:[6]i64
 for k:=0;k<3;k+=1{i:=6*k;ru[k]=[3]i64{v[i+1],2*v[i+3],v[i+4]};rv[k]=[3]i64{v[i+2],v[i+4],2*v[i+5]}}
 for k:=0;k<3;k+=1{product(ru[k],ru[k],&e);product(ru[k],rv[k],&f);product(rv[k],rv[k],&g)}
 h:=u64(0xcbf29ce484222325);for x in e{h=feed(h,x)};for x in f{h=feed(h,x)};for x in g{h=feed(h,x)};return transmute(i64)h
}
