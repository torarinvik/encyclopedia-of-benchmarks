module star_delta_conversions;
extern fn double floor(double x);
fn long star_delta_conversions(long* v, ulong n) @export("star_delta_conversions") {
 if(v==null||n!=4||(v[0]!=0&&v[0]!=1))return -1;
 for(ulong i=1;i<4;i++)if(v[i]<1000||v[i]>100000)return -1;
 double a=(double)v[1],b=(double)v[2],c=(double)v[3];double[3] out;
 if(v[0]==0){double p=a*b+b*c+c*a;out[0]=p/a;out[1]=p/b;out[2]=p/c;}else{double s=a+b+c;out[0]=b*c/s;out[1]=c*a/s;out[2]=a*b/s;}
 ulong h=0xcbf29ce484222325;for(int i=0;i<3;i++){long q=(long)floor(out[i]+0.5);ulong u=(ulong)q;for(int j=0;j<8;j++)h=(h^((u>>(8*j))&255))*0x100000001b3;}
 return (long)h;
}
