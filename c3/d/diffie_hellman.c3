module diffie_hellman;
fn long diffie_hellman(long* v, usz n) @export("diffie_hellman") {
 if(v==null||n!=4)return -1;long g=v[0]; long a=v[1]; long b=v[2]; long p=v[3];
 if(p<2||p>6700417||g<1||g>=p||a<1||a>=p||b<1||b>=p)return -1;
 long d=2;while(d*d<=p){if(p%d==0)return -1;d++;}
 long x=g; long e=a; long r=1;while(e>0){if((e&1)!=0)r=r*x%p;x=x*x%p;e>>=1;}
 x=r;e=b;r=1;while(e>0){if((e&1)!=0)r=r*x%p;x=x*x%p;e>>=1;}return r;
}
