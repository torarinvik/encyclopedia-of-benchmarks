module euler_modified;
fn void put64(char *out,usz i,double x){ulong b=@bitcast(ulong,x);for(usz k=0;k<8;k++){out[i*8+k]=(char)(b&255);b>>=8;}}
fn long euler_modified(long *v,usz n,char *out,usz cap) @export("euler_modified"){
 if(v==null||n!=2||v[0]<1||v[0]>8||v[1]<1||v[1]>4)return -1;usz steps=(usz)v[0];usz bytes=(steps+1)*8;if(out==null||cap<bytes)return -2;
 double h=0.25,x=0.0,y=(double)v[1];put64(out,0,y);
 for(usz i=0;i<steps;i++){double f0=-2.0*x*y*y;double predictor=y+h*f0;double f1=-2.0*(x+h)*predictor*predictor;y=y+(h/2.0)*(f0+f1);x+=h;put64(out,i+1,y);}return (long)bytes;
}
