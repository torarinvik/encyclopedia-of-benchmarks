/* Layered edit-distance shortest paths over a supplied literal NFA. */
#include <stddef.h>
#include <stdint.h>

int64_t approximate_regex_matching(const int64_t *x, size_t len, uint8_t *out, size_t cap) {
    if (x == NULL) return -2;
    if (len < 6 || len > 66) return -1;
    int64_t sv=x[0], ev=x[1], tv=x[2], kv=x[3], stv=x[4], av=x[5];
    if (sv<2||sv>8||ev<1||ev>16||tv<0||tv>12||kv<0||kv>3||stv<0||av<0||stv>=sv||av>=sv||stv==av) return -1;
    size_t s=(size_t)sv,e=(size_t)ev,t=(size_t)tv,k=(size_t)kv,start=(size_t)stv,accept=(size_t)av,ts=6+3*(size_t)ev;
    if(len!=ts+t)return -1;
    size_t from[16],to[16];uint8_t label[16];
    for(size_t i=0;i<e;i++){
        int64_t a=x[6+3*i],b=x[7+3*i],c=x[8+3*i];
        if(a<0||a>=sv||b<0||b>=sv||c<1||c>127)return -1;
        from[i]=(size_t)a;to[i]=(size_t)b;label[i]=(uint8_t)c;
        for(size_t j=0;j<i;j++)if(from[j]==from[i]&&to[j]==to[i]&&label[j]==label[i])return -1;
    }
    for(size_t i=0;i<t;i++)if(x[ts+i]<1||x[ts+i]>127)return -1;
    if(cap<t||(t>0&&out==NULL))return -2;
    int inf=(int)k+1,cur[8],next[8];for(size_t q=0;q<s;q++)cur[q]=inf;
    for(size_t pos=0;pos<t;pos++){
        cur[start]=0;
        for(size_t pass=0;pass<s-1;pass++){
            int changed=0;
            for(size_t i=0;i<e;i++)if(cur[from[i]]<inf&&cur[from[i]]+1<cur[to[i]]){cur[to[i]]=cur[from[i]]+1;changed=1;}
            if(!changed)break;
        }
        for(size_t q=0;q<s;q++)next[q]=cur[q]<inf?cur[q]+1:inf;
        for(size_t i=0;i<e;i++)if(cur[from[i]]<inf){int cost=cur[from[i]]+(label[i]!=(uint8_t)x[ts+pos]);if(cost<next[to[i]])next[to[i]]=cost;}
        for(size_t pass=0;pass<s-1;pass++){
            int changed=0;
            for(size_t i=0;i<e;i++)if(next[from[i]]<inf&&next[from[i]]+1<next[to[i]]){next[to[i]]=next[from[i]]+1;changed=1;}
            if(!changed)break;
        }
        if(next[accept]<=k)out[pos]=1;else out[pos]=0;
        for(size_t q=0;q<s;q++)cur[q]=next[q];
    }
    return (int64_t)t;
}
