module first_fundamental_form;
fn ulong feed(ulong hash,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){hash=(hash^((bits>>(b*8))&255))*0x100000001B3;}return hash;}
fn void product(long* a,long* b,long* o){o[0]+=a[0]*b[0];o[1]+=a[0]*b[1]+a[1]*b[0];o[2]+=a[0]*b[2]+a[2]*b[0];o[3]+=a[1]*b[1];o[4]+=a[1]*b[2]+a[2]*b[1];o[5]+=a[2]*b[2];}
fn long first_fundamental_form(long* v,usz n) @export("first_fundamental_form"){
 if(v==null||n!=18)return -1;for(usz i=0;i<18;i++)if(v[i]<-100||v[i]>100)return -1;
 long[9] ru,rv;long[18] out;for(usz i=0;i<18;i++)out[i]=0;for(usz k=0;k<3;k++){usz i=6*k;ru[3*k]=v[i+1];ru[3*k+1]=2*v[i+3];ru[3*k+2]=v[i+4];rv[3*k]=v[i+2];rv[3*k+1]=v[i+4];rv[3*k+2]=2*v[i+5];}
 for(usz k=0;k<3;k++){product(&ru[3*k],&ru[3*k],&out[0]);product(&ru[3*k],&rv[3*k],&out[6]);product(&rv[3*k],&rv[3*k],&out[12]);}
 ulong h=0xCBF29CE484222325;for(usz i=0;i<18;i++)h=feed(h,out[i]);return (long)h;
}
