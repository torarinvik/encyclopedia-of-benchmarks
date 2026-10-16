module quadratic_residue;
fn bool prime(long p){long[15] ps={3,5,7,11,13,17,19,23,29,31,37,41,43,47,53};for(usz i=0;i<15;i++)if(p==ps[i])return true;return false;}
fn long quadratic_residue(long* in,usz n) @export("quadratic_residue"){if(in==null||n!=2)return -1;long a=in[0],p=in[1];if(!prime(p)||a<0||a>=p)return -1;if(a==0)return 0;long r=1,b=a,e=(p-1)/2;while(e>0){if((e&1)!=0)r=(r*b)%p;b=(b*b)%p;e=e>>1;}return r==1?1:-1;}
