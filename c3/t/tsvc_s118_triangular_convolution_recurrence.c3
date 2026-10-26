// Clean-room TSVC s118 profile; see package rights note.
module tsvc_s118_triangular_convolution_recurrence;
fn void put64(&usz o,usz p,long v){usz b=(usz)v;for(usz j=0;j<8;j++){o[j]=(u8)(b&255);b>>=8;}}
fn long tsvc_s118_triangular_convolution_recurrence(&long in,usz len,&u8 out,usz cap){if(in==null||len<8||len>74)return -1;long nr=in[0],passes=in[1];if(nr<2||nr>8||passes<1||passes>4)return -1;usz n=(usz)nr;if(len!=2+n+n*n)return -1;long a[8];long b[64];for(usz i=0;i<n;i++){long x=in[2+i];if(x< -1||x>1)return -1;a[i]=x;}for(usz i=0;i<n*n;i++){long x=in[2+n+i];if(x< -1||x>1)return -1;b[i]=x;}if(out==null||cap<8*n)return -2;for(usz p=0;p<(usz)passes;p++)for(usz i=1;i<n;i++)for(usz j=0;j<i;j++)a[i]+=b[j*n+i]*a[i-j-1];for(usz i=0;i<n;i++)put64(out+8*i,a[i]);return n.long();}
