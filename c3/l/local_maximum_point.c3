module local_maximum_point;
fn long local_maximum_point(long*v,usz n) @export("local_maximum_point"){if(v==null||n<1||n>64)return -1;for(usz i=0;i<n;i++)if(v[i]<-1000000||v[i]>1000000)return -1;usz s=0;usz e=n-1;while(true){usz m=s+(e-s)/2;if((m==0||v[m-1]<=v[m])&&(m==n-1||v[m+1]<=v[m]))return m;if(m>0&&v[m-1]>v[m])e=m-1;else s=m+1;}}
