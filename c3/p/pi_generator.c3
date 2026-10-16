module pi_generator;
fn uint mix(uint h,uint8 b){return (h^b)*16777619;}
fn long pi_generator(long digits) @export("pi_generator"){if(digits<0||digits>8)return -1;long q=1;long r=0;long t=1;long k=1;long n=3;long m=3;long counter=0;uint h=2166136261;while(counter!=digits+1){if(4*q+r-t<n*t){h=mix(h,(uint8)(48+n));if(counter==0)h=mix(h,(uint8)46);if(digits==counter)break;counter++;long nr=10*(r-n*t);n=(10*(3*q+r))/t-10*n;q*=10;r=nr;}else{long nr=(2*q+r)*m;long nn=(q*(7*k)+2+r*m)/(t*m);q*=k;t*=m;m+=2;k++;n=nn;r=nr;}}return (long)h;}
