module permutation_calculation;
fn long factorial(long n){long x=1;for(long i=1;i<=n;i+=1)x*=i;return x;}
fn long permutation_calculation(long* v,usz n) @export("permutation_calculation"){if(v==null||n!=2||v[0]<0||v[0]>15||v[1]<0||v[1]>v[0])return -1;return factorial(v[0])/factorial(v[0]-v[1]);}
