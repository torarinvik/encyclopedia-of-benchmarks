/* Java WordLadder shortest sequence length over bounded base-26 words. */
#include <stddef.h>
#include <stdint.h>
int64_t word_ladder(const int64_t *in, size_t len, uint8_t *out, size_t cap) {
    if (!in || len < 4) return -1;
    int64_t width=in[0], start=in[1], end=in[2], count=in[3];
    if(width<1||width>5||count<0||count>32||len!=(size_t)(4+count)) return -1;
    int64_t limit=1; for(int i=0;i<width;i++) limit*=26;
    if(start<0||start>=limit||end<0||end>=limit) return -1;
    int64_t words[32]; for(int i=0;i<count;i++){words[i]=in[4+i];if(words[i]<0||words[i]>=limit)return -1;}
    int end_found=0;for(int i=0;i<count;i++)if(words[i]==end)end_found=1;
    int64_t result=0;
    if(end_found){
        int64_t queue[33], distance[33]; size_t head=0,tail=1; queue[0]=start;distance[0]=1;
        while(head<tail && !result){int64_t cur=queue[head],d=distance[head++];int64_t factor=1;
            for(int p=0;p<width&&!result;p++,factor*=26){int digit=(int)((cur/factor)%26);
                for(int ch=0;ch<26;ch++){if(ch==digit)continue;int64_t next=cur+(ch-digit)*factor;
                    if(next==end){result=d+1;break;}
                    int present=0,seen=0;for(int i=0;i<count;i++)if(words[i]==next)present=1;
                    for(size_t i=0;i<tail;i++)if(queue[i]==next)seen=1;
                    if(present&&!seen&&tail<33){queue[tail]=next;distance[tail++]=d+1;}
                }
            }
        }
    }
    if(!out||cap<8)return -2;uint64_t bits=(uint64_t)result;for(int i=0;i<8;i++)out[i]=(uint8_t)(bits>>(8*i));return 8;
}
