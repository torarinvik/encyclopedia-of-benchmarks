module modular_binary_exponentiation_recursive;
fn long power(long a,long e,long m){if(e==0)return 1;if(e%2==1)return (power(a,e-1,m)*a)%m;long h=power(a,e/2,m);return (h*h)%m;}
fn long modular_binary_exponentiation_recursive(long* v,usz n) @export("modular_binary_exponentiation_recursive"){if(v==null||n!=3)return -1;long a=v[0],e=v[1],m=v[2];if(a<0||a>1000000||e<0||e>60||m<2||m>1000000)return -1;return power(a,e,m);}
