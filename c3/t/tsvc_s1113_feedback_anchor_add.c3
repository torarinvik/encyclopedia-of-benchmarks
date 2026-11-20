// Clean-room TSVC s1113 profile; see package rights note.
module tsvc_s1113_feedback_anchor_add;
fn void put64(char* o,long v){ulong b=(ulong)v;for(usz j=0;j<8;j++){o[j]=(char)(b&255);b>>=8;}}
fn long tsvc_s1113_feedback_anchor_add(long* in,usz len,char* out,usz cap) @export("tsvc_s1113_feedback_anchor_add") {if(in==null||len<3||len>129)return -1;long nr=in[0];if(nr<1||nr>64)return -1;usz n=(usz)nr;if(len!=1+2*n)return -1;long[64] a;long[64] b;for(usz i=0;i<n;i++){long x=in[1+i],y=in[1+n+i];if(x< -2||x>2||y< -2||y>2)return -1;a[i]=x;b[i]=y;}if(out==null||cap<8*n)return -2;for(usz i=0;i<n;i++)a[i]=a[n/2]+b[i];for(usz j=0;j<n;j++)put64(out+8*j,a[j]);return (long)n;}
