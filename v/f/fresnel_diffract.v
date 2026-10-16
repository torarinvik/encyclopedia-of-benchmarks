module fresnel_diffract
import math
@[export: 'fresnel_diffract']
pub fn fresnel_diffract(v &f64,n usize,mut out &f64,cap usize)i64{
 unsafe{
  if v==nil||n!=12||v[0]!=4||v[1]!=1||v[2]!=1||v[3]!=16{return -1};for i in 4..12{if math.is_nan(v[i])||math.is_inf(v[i],0)||math.abs(v[i])>100{return -1}};if out==nil||cap<8{return -2}
  mut xr:=[4]f64{};mut xi:=[4]f64{};mut cr:=[4]f64{};mut si:=[4]f64{};mut fr:=[4]f64{};mut fi:=[4]f64{}
  xr[0]=v[6];xr[1]=v[7];xr[2]=v[4];xr[3]=v[5];xi[0]=v[10];xi[1]=v[11];xi[2]=v[8];xi[3]=v[9];cr[0]=1;cr[2]=-1;si[1]=-1;si[3]=1
  for k in 0..4{for j in 0..4{t:=(k*j)&3;fr[k]+=xr[j]*cr[t]-xi[j]*si[t];fi[k]+=xr[j]*si[t]+xi[j]*cr[t]}}
  for k in [1,3]{fr[k] = -fr[k];fi[k] = -fi[k]}
  mut zr:=[4]f64{};mut zi:=[4]f64{};for j in 0..4{for k in 0..4{t:=(k*j)&3;s:=-si[t];zr[j]+=(fr[k]*cr[t]-fi[k]*s)*0.25;zi[j]+=(fr[k]*s+fi[k]*cr[t])*0.25}}
  result:=[8]f64{};result[0]=zr[2];result[1]=zr[3];result[2]=zr[0];result[3]=zr[1];result[4]=zi[2];result[5]=zi[3];result[6]=zi[0];result[7]=zi[1];for i in 0..8{out[i]=result[i]};return 8
 }
}
