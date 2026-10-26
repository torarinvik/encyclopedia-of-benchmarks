module approximate_regex_matching;

fn long approximate_regex_matching(long* x, usz length, char* output, usz capacity)
    @export("approximate_regex_matching")
{
    if (x == null) return -2;
    if (length < 6 || length > 66) return -1;
    long sv=x[0], ev=x[1], tv=x[2], kv=x[3], startv=x[4], acceptv=x[5];
    if(sv<2||sv>8||ev<1||ev>16||tv<0||tv>12||kv<0||kv>3||startv<0||acceptv<0||startv>=sv||acceptv>=sv||startv==acceptv)return -1;
    usz s=(usz)sv,e=(usz)ev,t=(usz)tv,k=(usz)kv,start=(usz)startv,accept=(usz)acceptv,ts=6+3*(usz)ev;
    if(length!=ts+t)return -1;
    usz[16] from,to; char[16] label;
    for(usz i=0;i<e;i++){
        long u=x[6+3*i],v=x[7+3*i],c=x[8+3*i];if(u<0||u>=sv||v<0||v>=sv||c<1||c>127)return -1;
        from[i]=(usz)u;to[i]=(usz)v;label[i]=(char)c;
        for(usz j=0;j<i;j++)if(from[i]==from[j]&&to[i]==to[j]&&label[i]==label[j])return -1;
    }
    for(usz i=0;i<t;i++)if(x[ts+i]<1||x[ts+i]>127)return -1;
    if(capacity<t||(t>0&&output==null))return -2;
    long inf=(long)k+1;long[8] cur,next;for(usz q=0;q<s;q++)cur[q]=inf;
    for(usz pos=0;pos<t;pos++){
        cur[start]=0;
        for(usz pass=0;pass<s-1;pass++){bool changed=false;for(usz i=0;i<e;i++)if(cur[from[i]]<inf&&cur[from[i]]+1<cur[to[i]]){cur[to[i]]=cur[from[i]]+1;changed=true;}if(!changed)break;}
        for(usz q=0;q<s;q++)next[q]=cur[q]<inf?cur[q]+1:inf;
        for(usz i=0;i<e;i++)if(cur[from[i]]<inf){long cost=cur[from[i]]+(label[i]!=(char)x[ts+pos]);if(cost<next[to[i]])next[to[i]]=cost;}
        for(usz pass=0;pass<s-1;pass++){bool changed=false;for(usz i=0;i<e;i++)if(next[from[i]]<inf&&next[from[i]]+1<next[to[i]]){next[to[i]]=next[from[i]]+1;changed=true;}if(!changed)break;}
        output[pos]=(char)(next[accept]<=(long)k?1:0);for(usz q=0;q<s;q++)cur[q]=next[q];
    }
    return (long)t;
}
