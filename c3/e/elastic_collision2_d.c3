module elastic_collision2_d;
extern fn double hypot(double x, double y);
extern fn double floor(double x);
fn long elastic_collision2_d(long* v, ulong n) @export("elastic_collision2_d") {
 if(v==null||n!=12)return -1;
 for(ulong i=0;i<12;i++){if((i==0||i==1||i==6||i==7)&&(v[i]<-200000||v[i]>200000))return -1;if((i==2||i==3||i==8||i==9)&&(v[i]<-5000||v[i]>5000))return -1;}
 if(v[4]<1000||v[4]>100000||v[10]<1000||v[10]>100000||v[5]<1||v[5]>10000||v[11]<1||v[11]>10000)return -1;
 double dx=(double)(v[6]-v[0]); double dy=(double)(v[7]-v[1]); double dist=hypot(dx,dy); if(dist==0)return -1;
 double ox=(double)v[2]; double oy=(double)v[3]; if(!(dist<(double)(v[5]+v[11]))){double nx=dx/dist; double ny=dy/dist; double rv=(double)(v[8]-v[2])*nx+(double)(v[9]-v[3])*ny; if(rv<=0){double m1=(double)v[4]; double m2=(double)v[10]; double j=-2*rv/(1/m1+1/m2); ox-=j*nx/m1; oy-=j*ny/m1;}}
 long qx=(long)floor(ox+0.5); long qy=(long)floor(oy+0.5); if(qx< -32768||qx>32767||qy< -32768||qy>32767)return -1; return ((qx&0xffff)<<16)|(qy&0xffff);
}
