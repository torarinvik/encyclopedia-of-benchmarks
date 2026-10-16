module rgbhsvconversion;
extern fn double floor(double x);
extern fn double fabs(double x);
fn long round_even(double x){double f=floor(x);long q=(long)f;double d=x-f;if(d<0.5)return q;if(d>0.5)return q+1;return (q&1)==0?q:q+1;}
fn long rgbhsvconversion(long* v,ulong n) @export("rgbhsvconversion"){
 if(v==null||n!=4)return -1;
 if(v[0]==0){if(v[1]<0||v[1]>360000||v[2]<0||v[2]>1000||v[3]<0||v[3]>1000)return -1;double h=(double)v[1]/1000.0,s=(double)v[2]/1000.0,value=(double)v[3]/1000.0,c=value*s,sec=h/60.0,rem=sec-floor(sec/2.0)*2.0,x=c*(1.0-fabs(rem-1.0)),m=value-c;double r,g,b;if(sec<=1){r=c+m;g=x+m;b=m;}else if(sec<=2){r=x+m;g=c+m;b=m;}else if(sec<=3){r=m;g=c+m;b=x+m;}else if(sec<=4){r=m;g=x+m;b=c+m;}else if(sec<=5){r=x+m;g=m;b=c+m;}else{r=c+m;g=m;b=x+m;}return (round_even(255*r)<<16)|(round_even(255*g)<<8)|round_even(255*b);}
 if(v[0]!=1||v[1]<0||v[1]>255||v[2]<0||v[2]>255||v[3]<0||v[3]>255)return -1;double r=(double)v[1]/255.0,g=(double)v[2]/255.0,b=(double)v[3]/255.0,mx=r;if(g>mx)mx=g;if(b>mx)mx=b;double mn=r;if(g<mn)mn=g;if(b<mn)mn=b;double c=mx-mn,s=0.0;if(mx!=0)s=c/mx;double h=0.0;if(c!=0){if(mx==r)h=60.0*((g-b)/c);else if(mx==g)h=60.0*(2.0+(b-r)/c);else h=60.0*(4.0+(r-g)/c);}h=h+360.0-floor((h+360.0)/360.0)*360.0;long qh=round_even(h*1000.0),qs=round_even(s*1000000.0),qv=round_even(mx*1000000.0);return (qh<<40)|(qs<<20)|qv;
}
