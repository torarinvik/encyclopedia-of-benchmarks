module modular_multiplicative_inverse;
fn long modular_multiplicative_inverse(long* v,usz n) @export("modular_multiplicative_inverse") {if(v==null||n!=2)return -1;long a=v[0],m=v[1];if(m<2||m>1000000||a<0||a>=m)return -1;long r0=a,r1=m,s0=1,s1=0;while(r1!=0){long q=r0/r1,t=r0-q*r1;r0=r1;r1=t;t=s0-q*s1;s0=s1;s1=t;}if(r0==1)return (s0%m+m)%m;return -1;}
