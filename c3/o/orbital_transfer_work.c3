module orbital_transfer_work;
void put_double(char*out,double x){ulong bits=@bitcast(ulong,x);for(usz k=0;k<8;k++){out[k]=(char)(bits&255);bits>>=8;}}
fn long orbital_transfer_work(long*v,usz n,char*out,usz cap)@export("orbital_transfer_work"){if(v==null||n!=4)return -1;long a=v[0],b=v[1],r1=v[2],r2=v[3];if(a < -1000000000||a>1000000000||b < -1000000||b>1000000||r1<1||r1>1000000000||r2<1||r2>1000000000)return -1;if(out==null||cap<8)return -2;double work=(6.67430e-11*(double)a*(double)b/2.0)*(1.0/(double)r1-1.0/(double)r2);put_double(out,work);return 8;}
