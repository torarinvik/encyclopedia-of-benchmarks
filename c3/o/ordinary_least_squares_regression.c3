module ordinary_least_squares_regression;
fn void put_double(char* outp, usz offset, double value) { ulong bits=@bitcast(ulong,value); for(usz b=0;b<8;b++){outp[offset+b]=(char)(bits&255);bits>>=8;} }
fn long ordinary_least_squares_regression(long*v,usz n,char*outp,usz cap) @export("ordinary_least_squares_regression") {
 if(v==null||n<5||v[0]<2||v[0]>32||n!=(usz)(1+2*v[0]))return -1;usz count=(usz)v[0];double[32] xs,ys;double xm=0,ym=0;
 for(usz i=0;i<count;i++){long x=v[1+2*i],y=v[2+2*i];if(x < -10000||x>10000||y < -10000||y>10000)return -1;xs[i]=(double)x;ys[i]=(double)y;xm+=xs[i];ym+=ys[i];}xm/=(double)count;ym/=(double)count;double num=0,den=0;
 for(usz i=0;i<count;i++){double dx=xs[i]-xm;num+=dx*(ys[i]-ym);den+=dx*dx;}if(den==0)return -1;double slope=num/den,intercept=ym-slope*xm;if(outp==null||cap<16)return -2;put_double(outp,0,intercept);put_double(outp,8,slope);return 16;
}
