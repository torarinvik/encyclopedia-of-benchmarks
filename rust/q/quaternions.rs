#[no_mangle]
pub unsafe extern "C" fn quaternions(input: *const f64, length: usize, output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 10 { return -1; }
    let x=std::slice::from_raw_parts(input,length); if x.iter().any(|v|!v.is_finite()){return -1;}
    let op=x[0];if op!=0.0&&op!=1.0&&op!=2.0{return -1;}let mode=op as i32;let expected=if mode==0{4}else if mode==1{5}else{9};let count=if mode==1{3}else{4};if length!=expected{return -1;}
    let mut v=[0.0f32;8];
    if mode==0{for i in 1..4{if x[i]<-3.0||x[i]>3.0{return -1;}v[i-1]=x[i] as f32;}}
    else if mode==1{for i in 1..5{v[i-1]=x[i] as f32;if v[i-1]<-1.0||v[i-1]>1.0{return -1;}}let(w,a,b,c)=(v[0],v[1],v[2],v[3]);let mut norm=w*w;norm=norm+a*a;norm=norm+b*b;norm=norm+c*c;if (norm-1.0).abs()>1e-6{return -1;}let mut pa=w*b+a*c;pa=2.0*pa;if pa < -1.0||pa>1.0{return -1;}}
    else{for i in 1..9{if x[i]<-1.0||x[i]>1.0{return -1;}v[i-1]=x[i] as f32;}}
    if output.is_null()||capacity<count{return -2;}let mut r=[0.0f32;4];
    if mode==0{let(y,p,roll)=(v[0],v[1],v[2]);let(cy,sy)=((y*0.5).cos(),(y*0.5).sin());let(cp,sp)=((p*0.5).cos(),(p*0.5).sin());let(cr,sr)=((roll*0.5).cos(),(roll*0.5).sin());r[0]=(cr*cp)*cy+(sr*sp)*sy;r[1]=(sr*cp)*cy-(cr*sp)*sy;r[2]=(cr*sp)*cy+(sr*cp)*sy;r[3]=(cr*cp)*sy-(sr*sp)*cy;}
    else if mode==1{let(w,a,b,c)=(v[0],v[1],v[2],v[3]);let ry=2.0*(w*a+b*c);let rx=1.0-2.0*(a*a+b*b);let pitch=(2.0*(w*b+a*c)).asin();let yy=2.0*(w*c+a*b);let yx=1.0-2.0*(b*b+c*c);r[0]=ry.atan2(rx);r[1]=pitch;r[2]=yy.atan2(yx);}
    else{let(aw,a1,a2,a3,bw,b1,b2,b3)=(v[0],v[1],v[2],v[3],v[4],v[5],v[6],v[7]);r[0]=((aw*bw-a1*b1)-a2*b2)-a3*b3;r[1]=((aw*b1+a1*bw)+a2*b3)-a3*b2;r[2]=((aw*b2-a1*b3)+a2*bw)+a3*b1;r[3]=((aw*b3+a1*b2)-a2*b1)+a3*bw;}
    for i in 0..count{*output.add(i)=r[i] as f64;}count as i64
}
