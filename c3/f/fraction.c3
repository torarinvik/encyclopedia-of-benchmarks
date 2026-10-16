module fraction;
fn long gcd_pos(long a,long b){if(a<0)a=-a;if(b<0)b=-b;while(b!=0){long r=a%b;a=b;b=r;}return a;}
fn void put64(char *o,usz p,long x){ulong b=@bitcast(ulong,x);for(usz i=0;i<8;i++){o[p+i]=(char)(b&255);b>>=8;}}
fn long fraction(long *v,usz n,char *o,usz cap) @export("fraction"){if(v==null||n!=4)return -1;long n1=v[0],d1=v[1],n2=v[2],d2=v[3];if(n1 < -10000||n1>10000||n2 < -10000||n2>10000||d1 < -1000||d1>1000||d2 < -1000||d2>1000||d1==0||d2==0)return -1;if(o==null||cap<16)return -2;long g=gcd_pos(d1,d2);long num=(d2/g)*n1+(d1/g)*n2;long den=(d1/g)*d2;long r=gcd_pos(num,den);num/=r;den/=r;if(den<0){num=-num;den=-den;}put64(o,0,num);put64(o,8,den);return 16;}
