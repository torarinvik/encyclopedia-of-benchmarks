/* Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
 * Apache-2.0 licensed upstream kernel, bounded variant; modifications made. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 32
typedef struct { uint16_t data; int32_t idx; int next; } Node;

static uint16_t crc_byte(uint8_t value, uint16_t crc) {
    for (unsigned bit=0;bit<8;++bit) {
        uint16_t mix=(uint16_t)((value&1u)^(crc&1u)); value>>=1;
        if(mix) crc^=0x4002u;
        crc>>=1;
        if(mix) crc|=0x8000u; else crc&=0x7fffu;
    }
    return crc;
}
static uint16_t crc16(uint16_t value,uint16_t crc){crc=crc_byte((uint8_t)value,crc);return crc_byte((uint8_t)(value>>8),crc);}
static int cmp(Node *a,Node *b,int complex,uint16_t seed){
    if(complex){
        if(!(a->data&0x80u)) a->data=(uint16_t)((a->data&0xff00u)|0x80u|((a->data^(a->data>>8)^seed)&0x7fu));
        if(!(b->data&0x80u)) b->data=(uint16_t)((b->data&0xff00u)|0x80u|((b->data^(b->data>>8)^seed)&0x7fu));
        return (int)(a->data&0x7fu)-(int)(b->data&0x7fu);
    }
    a->data=(uint16_t)((a->data&0xff00u)|((a->data>>8)&0xffu));
    b->data=(uint16_t)((b->data&0xff00u)|((b->data>>8)&0xffu));
    return a->idx-b->idx;
}
static int sort_list(Node *nodes,int head,int complex,uint16_t seed){
    int width=1;
    for(;;){int p=head,new_head=-1,tail=-1,merges=0;
        while(p>=0){++merges;int q=p,ps=0;
            for(int i=0;i<width;++i){++ps;q=nodes[q].next;if(q<0)break;}
            int qs=width;
            while(ps>0||(qs>0&&q>=0)){
                int e;
                if(ps==0){e=q;q=nodes[q].next;--qs;}
                else if(qs==0||q<0){e=p;p=nodes[p].next;--ps;}
                else if(cmp(&nodes[p],&nodes[q],complex,seed)<=0){e=p;p=nodes[p].next;--ps;}
                else{e=q;q=nodes[q].next;--qs;}
                if(tail>=0)nodes[tail].next=e;else new_head=e;tail=e;
            }
            p=q;
        }
        nodes[tail].next=-1;head=new_head;if(merges<=1)return head;width*=2;
    }
}
static int find_node(Node *nodes,int head,int target_idx,int target_data){
    for(int p=head;p>=0;p=nodes[p].next)
        if(target_idx>=0?nodes[p].idx==target_idx:(nodes[p].data&255u)==(uint16_t)target_data)return p;
    return -1;
}
static void reverse_list(Node *nodes,int *head){int prev=-1,cur=*head;while(cur>=0){int next=nodes[cur].next;nodes[cur].next=prev;prev=cur;cur=next;}*head=prev;}
static void put_u16(uint8_t *out,uint16_t x){out[0]=(uint8_t)x;out[1]=(uint8_t)(x>>8);}

int64_t embedded_list_stress(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length!=4)return -1;
    int64_t raw_n=input[0],seed=input[1],find_count=input[2],finder_idx=input[3];
    if(raw_n<4||raw_n>MAX_ITEMS||seed<1||seed>255||find_count<0||find_count>32||!(finder_idx==-1||finder_idx==1))return -1;
    int n=(int)raw_n,head=0,tail=n+1;Node nodes[MAX_ITEMS+2]={0};
    nodes[0]=(Node){0x8080u,0,1};nodes[tail]=(Node){0xffffu,0x7fff,-1};
    for(int i=0;i<n;++i){uint16_t pat=(uint16_t)((seed^i)&15);uint16_t dat=(uint16_t)((pat<<3)|(i&7));nodes[i+1]=(Node){(uint16_t)((dat<<8)|dat),0, i+2};}
    nodes[n].next=tail;
    int i=1;
    for(int p=nodes[head].next;p!=tail;p=nodes[p].next){if(i<n/5)nodes[p].idx=i++;else{uint16_t pat=(uint16_t)(i++^seed);nodes[p].idx=(int32_t)(((i&7)<<8)|pat)&0x3fff;}}
    head=sort_list(nodes,head,0,(uint16_t)seed);
    int info_idx=(int)finder_idx;int info_data=0;uint16_t retval=0;unsigned found=0,missed=0;
    for(int k=0;k<(int)find_count;++k){info_data=k&255;int got=find_node(nodes,head,info_idx,info_data);reverse_list(nodes,&head);
        if(got<0){++missed;int first=nodes[head].next;if(first>=0)retval=(uint16_t)(retval+((nodes[first].data>>8)&1));}
        else{++found;if(nodes[got].data&1u)retval=(uint16_t)(retval+((nodes[got].data>>9)&1));int next=nodes[got].next;if(next>=0){nodes[got].next=nodes[next].next;nodes[next].next=nodes[head].next;nodes[head].next=next;}}
        if(info_idx>=0)++info_idx;
    }
    retval=(uint16_t)(retval+found*4-missed);
    if(finder_idx>0)head=sort_list(nodes,head,1,(uint16_t)seed);
    int remove_at=nodes[head].next;if(remove_at>=0){int removed=nodes[remove_at].next;uint16_t temp=nodes[remove_at].data;nodes[remove_at].data=nodes[removed].data;nodes[removed].data=temp;int32_t ti=nodes[remove_at].idx;nodes[remove_at].idx=nodes[removed].idx;nodes[removed].idx=ti;nodes[remove_at].next=nodes[removed].next;nodes[removed].next=-1;
        int finder=find_node(nodes,head,info_idx,info_data);if(finder<0)finder=nodes[head].next;
        while(finder>=0){retval=crc16(nodes[head].data,retval);finder=nodes[finder].next;}
        temp=nodes[removed].data;nodes[removed].data=nodes[remove_at].data;nodes[remove_at].data=temp;ti=nodes[removed].idx;nodes[removed].idx=nodes[remove_at].idx;nodes[remove_at].idx=ti;nodes[removed].next=nodes[remove_at].next;nodes[remove_at].next=removed;
    }
    head=sort_list(nodes,head,0,(uint16_t)seed);
    int finder=nodes[head].next;while(finder>=0){retval=crc16(nodes[head].data,retval);finder=nodes[finder].next;}
    if(output==NULL||capacity<2)return -2;put_u16(output,retval);return 2;
}
