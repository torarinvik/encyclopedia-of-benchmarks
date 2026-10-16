module ones_and_zeros;
fn long ones_and_zeros(long*v,usz n) @export("ones_and_zeros") {
 if(v==null||n<3||v[0]<0||v[0]>32||v[1]<0||v[1]>32||v[2]<0||v[2]>32||n!=3+2*(usz)v[0])return -1;
 long[33][33] dp;
 for(usz i=0;i<(usz)v[0];i++){long z=v[3+2*i],o=v[4+2*i];if(z<0||z>32||o<0||o>32)return -1;long a=v[1];while(a>=z){long b=v[2];while(b>=o){long candidate=dp[(usz)(a-z)][(usz)(b-o)]+1;if(candidate>dp[(usz)a][(usz)b])dp[(usz)a][(usz)b]=candidate;b--;}a--;}}
 return dp[(usz)v[1]][(usz)v[2]];
}
