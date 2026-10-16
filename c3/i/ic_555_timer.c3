module ic_555_timer;
fn double ic_555_timer(long*v,usz n) @export("ic_555_timer"){if(v==null||n!=4)return -1e300;long m=v[0],a=v[1],b=v[2],c=v[3];if((m!=0&&m!=1)||a<1||a>1000000||b<1||b>1000000||(m==0&&(c<1||c>1000000))||(m==1&&(c<0||c>1000000)))return -1e300;if(m==0)return (1.44/((a+2*b).double()*c.double()))*1e6;return ((a+b).double()/(a+2*b).double())*100.0;}
