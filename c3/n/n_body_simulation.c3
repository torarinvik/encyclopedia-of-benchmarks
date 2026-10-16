module n_body_simulation;
extern fn double sqrt(double x);
void put_double(char*out,usz off,double x){ulong bits=@bitcast(ulong,x);for(usz k=0;k<8;k++){out[off+k]=(char)(bits&255);bits>>=8;}}
fn long n_body_simulation(long*v,usz n,char*out,usz cap)@export("n_body_simulation"){
 if(v==null||n<6)return -1;long nb=v[0],steps=v[1],dtm=v[2],gm=v[3],tf=v[4],sm=v[5];if(nb<2||nb>4||steps<0||steps>4||dtm<1||dtm>1000||gm<0||gm>1000||tf<1||tf>10||sm<1||sm>3000||n!=(usz)(6+5*nb))return -1;usz count=(usz)nb;double[4] x,y,vx,vy,mass;
 for(usz i=0;i<count;i++){long a=v[6+5*i],b=v[7+5*i],c=v[8+5*i],d=v[9+5*i],m=v[10+5*i];if(a < -1000||a>1000||b < -1000||b>1000||c < -100||c>100||d < -100||d>100||m<1||m>1000)return -1;x[i]=(double)a;y[i]=(double)b;vx[i]=(double)c;vy[i]=(double)d;mass[i]=(double)m;}
 double dt=((double)dtm/1000.0)*(double)tf,g=(double)gm/1000.0,soft=(double)sm/1000.0;for(long step=0;step<steps;step++){for(usz i=0;i<count;i++){double fx=0,fy=0;for(usz j=0;j<count;j++)if(i!=j){double dx=x[j]-x[i],dy=y[j]-y[i],dist=sqrt(dx*dx+dy*dy+soft),cube=dist*dist*dist;fx+=g*mass[j]*dx/cube;fy+=g*mass[j]*dy/cube;}vx[i]+=fx*dt;vy[i]+=fy*dt;}for(usz i=0;i<count;i++){x[i]+=vx[i]*dt;y[i]+=vy[i]*dt;}}
 usz bytes=count*32;if(out==null||cap<bytes)return -2;for(usz i=0;i<count;i++){put_double(out,4*i*8,x[i]);put_double(out,(4*i+1)*8,y[i]);put_double(out,(4*i+2)*8,vx[i]);put_double(out,(4*i+3)*8,vy[i]);}return (long)bytes;
}
