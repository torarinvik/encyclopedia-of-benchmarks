module equal_loudness_filter;
const long[11] A={1073741824,-3875279605,7242592440,-9849938776,11019995787,-10310050823,8022431451,-5130046574,2558322377,-874363774,153873500};
const long[11] B={60930872,-44894685,-5549718,-9621322,-7681698,30506759,-32060412,22380311,-4826655,8028337,-4488672};
const long[3] HA={1089966811,-2146993250,1057516837};
const long[3] HB={1073619225,-2147238449,1073619225};
fn long step(long sample,long* a,long* b,int order,long* x,long* y){long acc=b[0]*sample;for(int i=1;i<=order;i++)acc+=b[i]*x[i-1]-a[i]*y[i-1];long out=acc/a[0];for(int i=order-1;i>0;i--){x[i]=x[i-1];y[i]=y[i-1];}if(order>0){x[0]=sample;y[0]=out;}return out;}
fn long equal_loudness_filter(long* v,usz n) @export("equal_loudness_filter"){if(v==null||n<1||n>33)return -1;long count=v[0];if(count<0||count>32||n!=(usz)count+1)return -1;long[10] x;long[10] y;long[2] hx;long[2] hy;for(usz j=0;j<10;j++){x[j]=0;y[j]=0;}for(usz j=0;j<2;j++){hx[j]=0;hy[j]=0;}long out=0;for(long i=0;i<count;i++){if(v[i+1]<-1000000||v[i+1]>1000000)return -1;long mid=step(v[i+1],&A[0],&B[0],10,&x[0],&y[0]);out=step(mid,&HA[0],&HB[0],2,&hx[0],&hy[0]);}return out;}
