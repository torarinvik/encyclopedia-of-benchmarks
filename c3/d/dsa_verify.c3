module dsa_verify;
fn bool is_prime(long n){if(n<2)return false;for(long d=2;d*d<=n;d++)if(n%d==0)return false;return true;}
fn long mpow(long a,long e,long m){long r=1;a%=m;while(e>0){if((e&1)!=0)r=r*a%m;a=a*a%m;e>>=1;}return r;}
fn long dsa_verify(long*v,usz n) @export("dsa_verify") {if(v==null||n<7||n>15)return -1;long p=v[0];long q=v[1];long g=v[2];long y=v[3];long r=v[4];long s=v[5];long ml=v[6];if(ml<0||ml>8||n!=(usz)(7+ml))return -1;if(p<5||p>251||!is_prime(p)||q<2||q>=p||(p-1)%q!=0||!is_prime(q))return -1;if(g<2||g>=p||mpow(g,q,p)!=1||y<1||y>=p||mpow(y,q,p)!=1||r<1||r>=q||s<1||s>=q)return -1;long h=0;for(usz i=0;i<(usz)ml;i++){if(v[7+i]<0||v[7+i]>255)return -1;h=(h*256+v[7+i])%q;}long w=mpow(s,q-2,q);long u1=h*w%q;long u2=r*w%q;return ((mpow(g,u1,p)*mpow(y,u2,p)%p)%q==r) ? 1 : 0;}
