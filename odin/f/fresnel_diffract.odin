package fresnel_diffract
import "core:c"
import "core:math"
@(export)
fresnel_diffract :: proc "c" (v:[^]f64,n:c.size_t,out:[^]f64,cap:c.size_t)->i64 {
 if v==nil||n!=12||v[0]!=4||v[1]!=1||v[2]!=1||v[3]!=16{return -1};for i:=4;i<12;i+=1{if math.is_nan(v[i])||math.is_inf(v[i])||math.abs(v[i])>100{return -1}};if out==nil||cap<8{return -2}
 xr:=[4]f64{v[6],v[7],v[4],v[5]};xi:=[4]f64{v[10],v[11],v[8],v[9]};cr:=[4]f64{1,0,-1,0};si:=[4]f64{0,-1,0,1};fr:[4]f64;fi:[4]f64
 for k:=0;k<4;k+=1{for j:=0;j<4;j+=1{t:=(k*j)&3;fr[k]+=xr[j]*cr[t]-xi[j]*si[t];fi[k]+=xr[j]*si[t]+xi[j]*cr[t]}}
 for k:=1;k<4;k+=2{fr[k] = -fr[k];fi[k] = -fi[k]}
 zr:[4]f64;zi:[4]f64;for j:=0;j<4;j+=1{for k:=0;k<4;k+=1{t:=(k*j)&3;s:=-si[t];zr[j]+=(fr[k]*cr[t]-fi[k]*s)*0.25;zi[j]+=(fr[k]*s+fi[k]*cr[t])*0.25}}
 result:=[8]f64{zr[2],zr[3],zr[0],zr[1],zi[2],zi[3],zi[0],zi[1]};for i:=0;i<8;i+=1{out[i]=result[i]};return 8
}
