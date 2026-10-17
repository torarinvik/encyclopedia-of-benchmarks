package quaternions

import "core:c"
import "core:math"

@(export)
quaternions :: proc "c" (input:[^]f64,length:c.size_t,output:[^]f64,capacity:c.size_t)->i64 {
 if input==nil||length<1||length>10 do return -1
 for i:=0;i<int(length);i+=1{if input[i]!=input[i] do return -1}
 op:=input[0];if op!=0.0&&op!=1.0&&op!=2.0 do return -1;mode:=int(op);expected:=if mode==0{4}else if mode==1{5}else{9};count:=if mode==1{3}else{4};if int(length)!=expected do return -1
 var v:[8]f32
 if mode==0{for i:=1;i<4;i+=1{if input[i]<-3.0||input[i]>3.0 do return -1;v[i-1]=f32(input[i])}}else if mode==1{for i:=1;i<5;i+=1{v[i-1]=f32(input[i]);if v[i-1]<-1.0||v[i-1]>1.0 do return -1};w,a,b,c0:=v[0],v[1],v[2],v[3];norm:=w*w;norm=norm+a*a;norm=norm+b*b;norm=norm+c0*c0;if math.abs(norm-1.0)>1e-6 do return -1;pa:=2.0*(w*b+a*c0);if pa < -1.0||pa>1.0 do return -1}else{for i:=1;i<9;i+=1{if input[i]<-1.0||input[i]>1.0 do return -1;v[i-1]=f32(input[i])}}
 if output==nil||capacity<c.size_t(count) do return -2
 var r:[4]f32
 if mode==0{y,p,roll:=v[0],v[1],v[2];cy,sy:=math.cos(y*0.5),math.sin(y*0.5);cp,sp:=math.cos(p*0.5),math.sin(p*0.5);cr,sr:=math.cos(roll*0.5),math.sin(roll*0.5);r[0]=(cr*cp)*cy+(sr*sp)*sy;r[1]=(sr*cp)*cy-(cr*sp)*sy;r[2]=(cr*sp)*cy+(sr*cp)*sy;r[3]=(cr*cp)*sy-(sr*sp)*cy}else if mode==1{w,a,b,c0:=v[0],v[1],v[2],v[3];ry:=2.0*(w*a+b*c0);rx:=1.0-2.0*(a*a+b*b);pitch:=math.asin(2.0*(w*b+a*c0));yy:=2.0*(w*c0+a*b);yx:=1.0-2.0*(b*b+c0*c0);r[0]=math.atan2(ry,rx);r[1]=pitch;r[2]=math.atan2(yy,yx)}else{aw,a1,a2,a3,bw,b1,b2,b3:=v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7];r[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;r[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;r[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;r[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw}
 for i:=0;i<count;i+=1{output[i]=f64(r[i])};return i64(count)
}
