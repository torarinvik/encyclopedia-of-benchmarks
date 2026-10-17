module quaternions

import math

@[export: 'quaternions']
pub fn quaternions(input &f64,length usize,mut output &f64,capacity usize)i64{
 if length<1||length>10{return -1};unsafe{if input==nil{return -1};for i in 0..int(length){if input[i]!=input[i]{return -1}};op:=input[0];if op!=0.0&&op!=1.0&&op!=2.0{return -1};mode:=int(op);expected:=if mode==0{4}else if mode==1{5}else{9};count:=if mode==1{3}else{4};if int(length)!=expected{return -1};mut v:=[8]f32{}
 if mode==0{for i in 1..4{if input[i]<-3.0||input[i]>3.0{return -1};v[i-1]=f32(input[i])}}else if mode==1{for i in 1..5{v[i-1]=f32(input[i]);if v[i-1]<-1.0||v[i-1]>1.0{return -1}};w,a,b,c:=v[0],v[1],v[2],v[3];mut norm:=w*w;norm=norm+a*a;norm=norm+b*b;norm=norm+c*c;if math.abs(norm-1.0)>1e-6{return -1};pa:=2.0*(w*b+a*c);if pa < -1.0||pa>1.0{return -1}}else{for i in 1..9{if input[i]<-1.0||input[i]>1.0{return -1};v[i-1]=f32(input[i])}}
 if output==nil||capacity<usize(count){return -2};mut r:=[4]f32{}
 if mode==0{y,p,roll:=v[0],v[1],v[2];cy,sy:=math.cos(y*0.5),math.sin(y*0.5);cp,sp:=math.cos(p*0.5),math.sin(p*0.5);cr,sr:=math.cos(roll*0.5),math.sin(roll*0.5);r[0]=(cr*cp)*cy+(sr*sp)*sy;r[1]=(sr*cp)*cy-(cr*sp)*sy;r[2]=(cr*sp)*cy+(sr*cp)*sy;r[3]=(cr*cp)*sy-(sr*sp)*cy}else if mode==1{w,a,b,c:=v[0],v[1],v[2],v[3];ry:=2.0*(w*a+b*c);rx:=1.0-2.0*(a*a+b*b);pitch:=math.asin(2.0*(w*b+a*c));yy:=2.0*(w*c+a*b);yx:=1.0-2.0*(b*b+c*c);r[0]=math.atan2(ry,rx);r[1]=pitch;r[2]=math.atan2(yy,yx)}else{aw,a1,a2,a3,bw,b1,b2,b3:=v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7];r[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;r[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;r[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;r[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw}
 for i in 0..count{output[i]=f64(r[i])};return i64(count)}}
