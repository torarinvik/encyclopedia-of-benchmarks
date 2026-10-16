module long_division;
fn long core(long a,long b){if(b==0)return 0;bool neg=(a<0)!=(b<0);if(a<0)a=-a;if(b<0)b=-b;long digits[16];usz n=0;if(a==0){digits[n]=0;n++;}while(a!=0){digits[n]=a%10;a=a/10;n++;}long rem=0;long q=0;while(n>0){n--;rem=rem*10+digits[n];long d=0;while(rem>=b){rem-=b;d++;}q=q*10+d;}if(neg)return -q;return q;}
fn long long_division(long*v,usz n) @export("long_division"){if(v==null||n!=2||v[0]<-1000000||v[0]>1000000||v[1]<-10000||v[1]>10000)return -1;return core(v[0],v[1]);}
