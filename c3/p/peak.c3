module peak;
fn long find_peak(long* a,usz lo,usz hi){usz m=(hi-lo)/2;long l=a[lo+m-1],c=a[lo+m],r=a[lo+m+1];if(c>l&&c>r)return c;if(l<r){usz start=m;if(m==2)start--;return find_peak(a,lo+start,hi);}usz end=m;if(m==2)end++;return find_peak(a,lo,lo+end);}
fn long peak(long* v,usz n) @export("peak"){if(v==null||n<4||n>65||v[0]<3||v[0]>64||n!=(usz)v[0]+1)return -1;usz len=(usz)v[0],p=1;for(usz i=0;i<len;i++)if(v[i+1]<-1000000||v[i+1]>1000000)return -1;while(p<len-1&&v[p+1]>v[p])p++;if(p==1||p>=len-1)return -1;for(usz i=p;i<len-1;i++)if(v[i+2]>=v[i+1])return -1;return find_peak(&v[1],0,len);}
