module line_sweep;
fn double line_sweep(long*v,usz n) @export("line_sweep"){if(n<1||n>17)return -1e300;long count=v[0];if(count<0||count>8||n!=usz(1+2*count))return -1e300;if(count==0)return 0.0;int line[22]={0};for(long i=0;i<count;i++){long s=v[1+2*i],e=v[2+2*i];if(s<0||e<s||e>20)return -1e300;line[s]++;line[e+1]--;}int c=0,m=0;for(int i=0;i<22;i++){c+=line[i];if(c>m)m=c;}return m>1?1.0:0.0;}
