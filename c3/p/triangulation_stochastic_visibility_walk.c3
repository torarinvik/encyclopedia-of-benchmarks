module triangulation_stochastic_visibility_walk;

fn long tsw_cross(long ax,long ay,long bx,long by,long px,long py) {
    return (bx-ax)*(py-ay)-(by-ay)*(px-ax);
}
fn bool tsw_same(int a,int b,int c,int d) { return (a==c&&b==d)||(a==d&&b==c); }
fn bool tsw_on(long ax,long ay,long bx,long by,long px,long py) {
    return tsw_cross(ax,ay,bx,by,px,py)==0 && px>=min(ax,bx) && px<=max(ax,bx) && py>=min(ay,by) && py<=max(ay,by);
}
fn bool tsw_intersect(long ax,long ay,long bx,long by,long cx,long cy,long dx,long dy) {
    long o1=tsw_cross(ax,ay,bx,by,cx,cy),o2=tsw_cross(ax,ay,bx,by,dx,dy);
    long o3=tsw_cross(cx,cy,dx,dy,ax,ay),o4=tsw_cross(cx,cy,dx,dy,bx,by);
    if ((o1==0&&tsw_on(ax,ay,bx,by,cx,cy))||(o2==0&&tsw_on(ax,ay,bx,by,dx,dy))||
        (o3==0&&tsw_on(cx,cy,dx,dy,ax,ay))||(o4==0&&tsw_on(cx,cy,dx,dy,bx,by))) return true;
    return ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0));
}

fn long triangulation_stochastic_visibility_walk(long* input,usz length) @export("triangulation_stochastic_visibility_walk") {
    if (input==null||length<8||length>57) return -1;
    long vr=input[0],br=input[1],tr=input[2],sr=input[3],px=input[4],py=input[5],capr=input[6],kr=input[7];
    if (vr<3||vr>6||br<3||br>vr||tr!=2*vr-br-2||tr<1||tr>7||sr<0||sr>=tr||capr<0||capr>12||kr<0||kr>12||px< -200||px>200||py< -200||py>200) return -1;
    int v=(int)vr,bcount=(int)br,tcount=(int)tr,start=(int)sr,cap=(int)capr,k=(int)kr;
    if (length!=(usz)(8+2*v+bcount+3*tcount+k)) return -1;
    long[6] xs={0},ys={0};int[6] boundary={0},faces[21]={0},neighbors[21]={0};bool[6] used={false};
    usz cursor=8;
    for(int i=0;i<v;i++){xs[i]=input[cursor++];ys[i]=input[cursor++];if(xs[i]< -200||xs[i]>200||ys[i]< -200||ys[i]>200)return -1;for(int j=0;j<i;j++)if(xs[i]==xs[j]&&ys[i]==ys[j])return -1;}
    for(int i=0;i<bcount;i++){long raw=input[cursor++];if(raw<0||raw>=vr)return -1;boundary[i]=(int)raw;for(int j=0;j<i;j++)if(boundary[i]==boundary[j])return -1;}
    for(int i=0;i<bcount;i++){int a=boundary[i],b=boundary[(i+1)%bcount];for(int j=0;j<bcount;j++){int c=boundary[j];if(c!=a&&c!=b&&tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0)return -1;}}
    for(int p=0;p<v;p++){bool on_boundary=false;for(int j=0;j<bcount;j++)if(boundary[j]==p)on_boundary=true;if(!on_boundary)for(int j=0;j<bcount;j++){int a=boundary[j],b=boundary[(j+1)%bcount];if(tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p])<=0)return -1;}}
    long area_sum=0;
    for(int f=0;f<tcount;f++){for(int e=0;e<3;e++){long raw=input[cursor++];if(raw<0||raw>=vr)return -1;faces[f*3+e]=(int)raw;}int a=faces[f*3],b=faces[f*3+1],c=faces[f*3+2];if(a==b||b==c||c==a||tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0)return -1;used[a]=used[b]=used[c]=true;area_sum+=tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c]);for(int g=0;g<f;g++){bool same=true;for(int e=0;e<3;e++){bool found=false;for(int j=0;j<3;j++)if(faces[f*3+e]==faces[g*3+j])found=true;if(!found)same=false;}if(same)return -1;}for(int e=0;e<3;e++)neighbors[f*3+e]=-1;}
    for(int i=0;i<v;i++)if(!used[i])return -1;
    long polygon_area=0;for(int i=0;i<bcount;i++){int a=boundary[i],b=boundary[(i+1)%bcount];polygon_area+=xs[a]*ys[b]-ys[a]*xs[b];}if(polygon_area<=0||polygon_area!=area_sum)return -1;
    for(int i=0;i<bcount;i++){int a=boundary[i],b=boundary[(i+1)%bcount],owners=0;for(int f=0;f<tcount;f++)for(int e=0;e<3;e++)if(tsw_same(a,b,faces[f*3+e],faces[f*3+(e+1)%3]))owners++;if(owners!=1)return -1;}
    for(int f=0;f<tcount;f++)for(int e=0;e<3;e++){int a=faces[f*3+e],b=faces[f*3+(e+1)%3];bool first=true;for(int g=0;g<=f;g++)for(int ge=0;ge<3;ge++){if(g==f&&ge>=e)continue;if(tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3]))first=false;}if(!first)continue;for(int p=0;p<v;p++)if(p!=a&&p!=b&&tsw_on(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p]))return -1;for(int g=f;g<tcount;g++)for(int ge=0;ge<3;ge++){if(g==f&&ge<=e)continue;int c=faces[g*3+ge],d=faces[g*3+(ge+1)%3];if(a==c||a==d||b==c||b==d)continue;if(tsw_intersect(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c],xs[d],ys[d]))return -1;}}
    for(int f=0;f<tcount;f++)for(int e=0;e<3;e++){int a=faces[f*3+e],b=faces[f*3+(e+1)%3];bool boundary_edge=false;for(int i=0;i<bcount;i++)if(tsw_same(a,b,boundary[i],boundary[(i+1)%bcount]))boundary_edge=true;int owners=0,other=-1,first_u=-1,first_v=-1;for(int g=0;g<tcount;g++)for(int ge=0;ge<3;ge++)if(tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3])){if(owners==0){first_u=faces[g*3+ge];first_v=faces[g*3+(ge+1)%3];}else if(faces[g*3+ge]!=first_v||faces[g*3+(ge+1)%3]!=first_u)return -1;owners++;if(g!=f)other=g;}if(owners!=(boundary_edge?1:2))return -1;if(!boundary_edge)neighbors[f*3+e]=other;}
    for(int i=0;i<k;i++)if(input[cursor+i]<0||input[cursor+i]>1)return -1;
    for(int i=0;i<bcount;i++){int a=boundary[i],b=boundary[(i+1)%bcount];if(tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)<=0)return -1;}
    int containing=0;for(int f=0;f<tcount;f++){int a=faces[f*3],b=faces[f*3+1],c=faces[f*3+2];if(tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)>0&&tsw_cross(xs[b],ys[b],xs[c],ys[c],px,py)>0&&tsw_cross(xs[c],ys[c],xs[a],ys[a],px,py)>0)containing++;}if(containing!=1)return -1;
    int face=start,steps=0,choice_index=0,status=0;long trace=face+1,predicates=0;
    for(;;){int eligible[3],count=0;int a=faces[face*3],b=faces[face*3+1],c=faces[face*3+2];int eu[3]={a,b,c},ev[3]={b,c,a};for(int e=0;e<3;e++){predicates++;if(tsw_cross(xs[eu[e]],ys[eu[e]],xs[ev[e]],ys[ev[e]],px,py)<0)eligible[count++]=e;}if(count==0){status=0;break;}if(steps==cap){status=2;break;}int selected;if(count==1)selected=eligible[0];else if(count==2){if(choice_index==k){status=1;break;}selected=eligible[input[cursor+choice_index++]];}else return -1;face=neighbors[face*3+selected];if(face<0)return -1;steps++;trace=trace*9+face+1;}
    return (trace*40+predicates)*3+status;
}
