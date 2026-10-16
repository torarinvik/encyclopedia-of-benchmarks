module peak_element;
fn long peak(long* a,long lo,long hi,long n){long mid=lo+(hi-lo)/2;if((mid==0||a[mid-1]<=a[mid])&&(mid==n-1||a[mid+1]<=a[mid]))return mid;if(mid>0&&a[mid-1]>a[mid])return peak(a,lo,mid-1,n);return peak(a,mid+1,hi,n);}
fn long peak_element(long* v,usz n) @export("peak_element"){if(v==null||n<2||n>129||v[0]<1||v[0]>128||n!=(usz)v[0]+1)return -1;long count=v[0];for(long i=0;i<count;i++)if(v[i+1]<-2147483648||v[i+1]>2147483647)return -1;return peak(v+1,0,count-1,count);}
