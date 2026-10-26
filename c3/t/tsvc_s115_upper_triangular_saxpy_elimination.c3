// Clean-room TSVC s115 profile; see package rights note.
module tsvc_s115_upper_triangular_saxpy_elimination;
fn void put64(&usz o,usz p,long v){usz b=(usz)v;for(usz k=0;k<8;k++){o[k]=(u8)(b&255);b>>=8;}}
fn long tsvc_s115_upper_triangular_saxpy_elimination(&long in,usz len,&u8 out,usz cap){if(in==null||len<8||len>58)return -1;long nr=in[0],pr=in[1];if(nr<2||nr>7||pr<1||pr>3)return -1;usz n=(usz)nr,passes=(usz)pr;if(len!=2+n+n*n)return -1;long a[8],m[64];for(usz i=0;i<n;i++){long x=in[2+i];if(x< -1||x>1)return -1;a[i]=x;}for(usz i=0;i<n*n;i++){long x=in[2+n+i];if(x< -1||x>1)return -1;m[i]=x;}if(out==null||cap<8*n)return -2;for(usz p=0;p<passes;p++)for(usz j=0;j<n;j++)for(usz i=j+1;i<n;i++)a[i]-=m[j*n+i]*a[j];for(usz i=0;i<n;i++)put64(out+8*i,a[i]);return n.long();}
