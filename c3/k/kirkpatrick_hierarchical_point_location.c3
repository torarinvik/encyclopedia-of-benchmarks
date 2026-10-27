module kirkpatrick_hierarchical_point_location;
const usz MAX_VERTICES=16; const usz MAX_LEVELS=4; const usz MAX_FACES=8; const usz MAX_INPUT=268;

fn long cross(long ax,long ay,long bx,long by,long cx,long cy){return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax);}
fn bool on_segment(long ax,long ay,long bx,long by,long px,long py){return cross(ax,ay,bx,by,px,py)==0&&px>=(ax<bx?ax:bx)&&px<=(ax>bx?ax:bx)&&py>=(ay<by?ay:by)&&py<=(ay>by?ay:by);}
fn bool inside(long qx,long qy,long*t,long*xy){long a=t[0]*2,b=t[1]*2,c=t[2]*2;return cross(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy)>0&&cross(xy[b],xy[b+1],xy[c],xy[c+1],qx,qy)>0&&cross(xy[c],xy[c+1],xy[a],xy[a+1],qx,qy)>0;}
fn bool boundary(long qx,long qy,long*t,long*xy){for(usz e=0;e<3;e+=1){long a=t[e]*2,b=t[(e+1)%3]*2;if(on_segment(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy))return true;}return false;}
fn bool seg_hit(long ax,long ay,long bx,long by,long cx,long cy,long dx,long dy){long o1=cross(ax,ay,bx,by,cx,cy),o2=cross(ax,ay,bx,by,dx,dy),o3=cross(cx,cy,dx,dy,ax,ay),o4=cross(cx,cy,dx,dy,bx,by);if(o1==0&&on_segment(ax,ay,bx,by,cx,cy))return true;if(o2==0&&on_segment(ax,ay,bx,by,dx,dy))return true;if(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))return true;if(o4==0&&on_segment(cx,cy,dx,dy,bx,by))return true;return o1*o2<0&&o3*o4<0;}
fn bool closed_inside(long px,long py,long*t,long*xy){for(usz e=0;e<3;e+=1){long a=t[e]*2,b=t[(e+1)%3]*2;if(cross(xy[a],xy[a+1],xy[b],xy[b+1],px,py)<0)return false;}return true;}
fn bool tri_hit(long*a,long*b,long*xy){for(usz i=0;i<3;i+=1){long p=a[i]*2;if(closed_inside(xy[p],xy[p+1],b,xy))return true;p=b[i]*2;if(closed_inside(xy[p],xy[p+1],a,xy))return true;}for(usz i=0;i<3;i+=1)for(usz j=0;j<3;j+=1){long a0=a[i]*2,a1=a[(i+1)%3]*2,b0=b[j]*2,b1=b[(j+1)%3]*2;if(seg_hit(xy[a0],xy[a0+1],xy[a1],xy[a1+1],xy[b0],xy[b0+1],xy[b1],xy[b1+1]))return true;}return false;}
fn void put64(char*out,usz pos,long value){ulong bits=(ulong)value;for(usz j=0;j<8;j+=1){out[pos+j]=(char)(bits&255);bits>>=8;}}

long kirkpatrick_hierarchical_point_location(long*in,usz len,char*out,usz cap) @export("kirkpatrick_hierarchical_point_location") {
    if(in==null||len<14||len>MAX_INPUT)return -1;
    long nv=in[0],nl=in[1],qx=in[2],qy=in[3];if(nv<3||nv>(long)MAX_VERTICES||nl<1||nl>(long)MAX_LEVELS||qx< -1000||qx>1000||qy< -1000||qy>1000)return -1;
    long[MAX_VERTICES*2] xy=zeroed;long[MAX_LEVELS*MAX_FACES*3] faces=zeroed;long[MAX_LEVELS] face_count=zeroed;long[MAX_LEVELS*MAX_FACES] cc=zeroed;long[MAX_LEVELS*MAX_FACES*MAX_FACES] ids=zeroed;
    usz pos=4;
    for(usz v=0;v<(usz)nv;v+=1){xy[2*v]=in[pos];xy[2*v+1]=in[pos+1];pos+=2;if(xy[2*v]< -1000||xy[2*v]>1000||xy[2*v+1]< -1000||xy[2*v+1]>1000)return -1;}
    for(usz level=0;level<(usz)nl;level+=1){if(pos>=len)return -1;long count=in[pos];pos+=1;if(count<1||count>(long)MAX_FACES||(level==0&&count!=1))return -1;face_count[level]=count;
        for(usz f=0;f<(usz)count;f+=1){if(pos+3>len)return -1;usz base=(level*MAX_FACES+f)*3;for(usz k=0;k<3;k+=1){faces[base+k]=in[pos];pos+=1;if(faces[base+k]<0||faces[base+k]>=nv)return -1;}long a=faces[base]*2,b=faces[base+1]*2,c=faces[base+2]*2;if(faces[base]==faces[base+1]||faces[base]==faces[base+2]||faces[base+1]==faces[base+2]||cross(xy[a],xy[a+1],xy[b],xy[b+1],xy[c],xy[c+1])<=0)return -1;}
        if(level+1<(usz)nl)for(usz f=0;f<(usz)count;f+=1){if(pos>=len)return -1;long n=in[pos];pos+=1;if(n<1||n>(long)MAX_FACES||pos+(usz)n>len)return -1;cc[level*MAX_FACES+f]=n;for(usz j=0;j<(usz)n;j+=1){long child=in[pos];pos+=1;if(child<0||child>=(long)MAX_FACES||(j>0&&child<=ids[(level*MAX_FACES+f)*MAX_FACES+j-1]))return -1;ids[(level*MAX_FACES+f)*MAX_FACES+j]=child;}}
    }
    if(pos!=len)return -1;
    for(usz level=0;level+1<(usz)nl;level+=1)for(usz f=0;f<(usz)face_count[level];f+=1)for(usz j=0;j<(usz)cc[level*MAX_FACES+f];j+=1){long child=ids[(level*MAX_FACES+f)*MAX_FACES+j];if(child>=face_count[level+1]||!tri_hit(&faces[(level*MAX_FACES+f)*3],&faces[((level+1)*MAX_FACES+(usz)child)*3],&xy[0]))return -1;}
    for(usz level=0;level<(usz)nl;level+=1){long hits=0;for(usz f=0;f<(usz)face_count[level];f+=1){long*t=&faces[(level*MAX_FACES+f)*3];if(boundary(qx,qy,t,&xy[0]))return -1;if(inside(qx,qy,t,&xy[0]))hits+=1;}if(hits!=1)return -1;}
    long face=0,predicates=1;for(usz level=0;level+1<(usz)nl;level+=1){long found=-1;for(usz j=0;j<(usz)cc[level*MAX_FACES+(usz)face];j+=1){long child=ids[(level*MAX_FACES+(usz)face)*MAX_FACES+j];predicates+=1;if(inside(qx,qy,&faces[((level+1)*MAX_FACES+(usz)child)*3],&xy[0])){found=child;break;}}if(found<0)return -1;face=found;}
    if(out==null||cap<16)return -2;char[16] staged=zeroed;put64(&staged[0],0,face);put64(&staged[0],8,predicates);for(usz i=0;i<16;i+=1)out[i]=staged[i];return 16;
}
