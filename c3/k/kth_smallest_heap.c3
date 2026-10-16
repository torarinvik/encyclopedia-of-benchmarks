module kth_smallest_heap;
fn void down(long*h,usz n,usz i){while(true){usz l=2*i+1;usz r=l+1;usz m=i;if(l<n&&h[l]>h[m])m=l;if(r<n&&h[r]>h[m])m=r;if(m==i)return;long t=h[i];h[i]=h[m];h[m]=t;i=m;}}
fn long kth_smallest_heap(long*v,usz n) @export("kth_smallest_heap"){if(v==null||n<2||n>65)return -1;long k=v[0];if(k<1||k>=n)return -1;usz m=k;long h[64];for(usz i=0;i<m;i++){if(v[i+1]<-100000||v[i+1]>100000)return -1;h[i]=v[i+1];}for(usz i=m/2;i>0;i--)down(h,m,i-1);for(usz i=m+1;i<n;i++){long x=v[i];if(x<-100000||x>100000)return -1;if(x<=h[0]){h[0]=x;down(h,m,0);}}return h[0];}
