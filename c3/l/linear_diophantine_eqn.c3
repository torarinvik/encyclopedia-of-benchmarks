module linear_diophantine_eqn;
fn long gcdv(long a,long b){if(a<0)a=-a;if(b<0)b=-b;while(b!=0){long r=a%b;a=b;b=r;}return a;}
fn long linear_diophantine_eqn(long*v,usz n) @export("linear_diophantine_eqn"){if(v==null||n!=3||v[0]<-100000||v[0]>100000||v[1]==0||v[1]<-100000||v[1]>100000||v[2]<-1000000||v[2]>1000000)return -1;return v[2]%gcdv(v[0],v[1])==0?1:0;}
