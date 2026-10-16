module jaro_winkler;
fn double jaro_winkler(long* v, usz n) @export("jaro_winkler") {
 if(v==null||n<2||n>66)return -1e300;long n1=v[0];if(n1<0||n1>32||1+(usz)n1>=n)return -1e300;usz p2=1+(usz)n1;long n2=v[p2];if(n2<0||n2>32||n!=p2+1+(usz)n2)return -1e300;for(usz i=0;i<(usz)n1;i++)if(v[1+i]<0||v[1+i]>127)return -1e300;for(usz i=0;i<(usz)n2;i++)if(v[p2+1+i]<0||v[p2+1+i]>127)return -1e300;
 long[32] a;long[32] b;for(usz i=0;i<(usz)n1;i++)a[i]=v[1+i];for(usz i=0;i<(usz)n2;i++)b[i]=v[p2+1+i];int radius=(int)((n1<n2?n1:n2)/2);bool[32] u1=zeroed;bool[32] u2=zeroed;long[32] ma;long[32] mb;usz ca=0;usz cb=0;
 for(usz i=0;i<(usz)n1;i++){usz lo=i>(usz)radius?i-(usz)radius:0;usz hi=i+(usz)radius+1;if(hi>(usz)n2)hi=(usz)n2;for(usz j=lo;j<hi;j++)if(!u2[j]&&a[i]==b[j]){u2[j]=true;ma[ca]=a[i];ca++;break;}}
 for(usz i=0;i<(usz)n2;i++){usz lo=i>(usz)radius?i-(usz)radius:0;usz hi=i+(usz)radius+1;if(hi>(usz)n1)hi=(usz)n1;for(usz j=lo;j<hi;j++)if(!u1[j]&&b[i]==a[j]){u1[j]=true;mb[cb]=b[i];cb++;break;}}
 long tr=0;for(usz i=0;i<ca&&i<cb;i++)if(ma[i]!=mb[i])tr++;tr/=2;double jr=0.0;if(ca>0)jr=((double)ca/(double)n1+(double)ca/(double)n2+(double)(ca-tr)/(double)ca)/3.0;usz pr=0;while(pr<4&&pr<(usz)n1&&pr<(usz)n2&&a[pr]==b[pr])pr++;return jr+0.1*(double)pr*(1.0-jr);
}
