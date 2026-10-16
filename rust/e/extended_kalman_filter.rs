const BAD:f64=-1.0e300;
#[no_mangle]
pub unsafe extern "C" fn extended_kalman_filter(v:*const i64,n:usize)->f64{
 if v.is_null()||n<10||n>17{return BAD;} let v=std::slice::from_raw_parts(v,n);let steps=v[0];
 if steps<1||steps>8||n!=(9+steps) as usize{return BAD;}
 for i in 1..9{if v[i]< -10000||v[i]>10000{return BAD;}}for i in 9..n{if v[i]< -10000||v[i]>10000{return BAD;}}
 let sc=1000.0;let(mut x,mut y,mut p00,mut p01,mut p11)=(v[1] as f64/sc,v[2] as f64/sc,v[3] as f64/sc,v[4] as f64/sc,v[5] as f64/sc);let(q0,q1,r)=(v[6] as f64/sc,v[7] as f64/sc,v[8] as f64/sc);
 if v[1]< -2000||v[1]>2000||v[2]< -2000||v[2]>2000||p00<=0.0||p11<=0.0||p00*p11<=p01*p01||q0<0.0||q1<0.0||r<=0.0||r>10.0{return BAD;}
 for t in 0..steps as usize{let(f01,f10)=(0.1,0.1*x);let(nx,ny)=(x+f01*y,y+0.05*x*x);let(a,b,c)=(p00+2.0*f01*p01+f01*f01*p11+q0,f10*p00+(1.0+f01*f10)*p01+f01*p11,f10*f10*p00+2.0*f10*p01+p11+q1);x=nx;y=ny;p00=a;p01=b;p11=c;
 let(h0,pred,res)=(0.1*x,0.05*x*x+y,v[9+t] as f64/sc-(0.05*x*x+y));let s=h0*h0*p00+2.0*h0*p01+p11+r;if !(s>0.0)||!s.is_finite(){return BAD;}let(k0,k1)=((p00*h0+p01)/s,(p01*h0+p11)/s);x+=k0*res;y+=k1*res;
 let(a00,a01,a10,a11)=(1.0-k0*h0,-k0,-k1*h0,1.0-k1);let(z00,z01,z11)=(a00*a00*p00+2.0*a00*a01*p01+a01*a01*p11+k0*k0*r,a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r,a10*a10*p00+2.0*a10*a11*p01+a11*a11*p11+k1*k1*r);p00=z00;p01=z01;p11=z11;let _=pred;
 }x
}
