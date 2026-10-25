module embench_aha_mont64;
fn void wide(ulong a,ulong b,ulong* hi,ulong* lo){ulong mask=0xffffffff;ulong a0=a&mask,a1=a>>32,b0=b&mask,b1=b>>32;ulong p00=a0*b0,p01=a0*b1,p10=a1*b0,p11=a1*b1;ulong l=p00,old=l;l+=p01<<32;ulong h=p11+(p01>>32);if(l<old)h++;old=l;l+=p10<<32;h+=p10>>32;if(l<old)h++;*hi=h;*lo=l;}
fn ulong mont(ulong a,ulong b,ulong m,ulong np){ulong th,tl,uh,ul;wide(a,b,&th,&tl);wide(tl*np,m,&uh,&ul);ulong lo=tl+ul,hi=th+uh;if(lo<tl)hi++;bool ov=hi<th||((hi==th)&&(lo<tl));if(ov||hi>=m)return hi-m;return hi;}
fn ulong nprime(ulong m){ulong x=1;for(int i=0;i<6;i++)x*=2-m*x;return 0-x;}
fn long embench_aha_mont64(long* values,usz length) @export("embench_aha_mont64"){if(values==null||length!=3||values[0]<0||values[1]<0||values[2]<3||(values[2]&1)==0)return -1;ulong a=(ulong)values[0],b=(ulong)values[1],m=(ulong)values[2];if(a>=m||b>=m)return -1;return (long)mont(a,b,m,nprime(m));}
