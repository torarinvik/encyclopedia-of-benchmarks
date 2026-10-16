module skip_list_unique_key_set;

const usz MAX_OPS=128;
const int MAX_LEVELS=8;
const long MIN_KEY=-2147483647L;
const long MAX_KEY=2147483646L;
struct Node{long key;long value;int level;int[MAX_LEVELS] next;}
fn int random_level(uint* state){int level=1;do{*state = *state ^ (*state << 13);*state = *state ^ (*state >> 17);*state = *state ^ (*state << 5);if((*state&1)!=0)break;level++;}while(level<MAX_LEVELS);return level;}
fn int find_update(Node* nodes,int active,long key,int* update){int current=0;for(int level=active-1;level>=0;level--){while(nodes[current].next[level]!=0&&nodes[nodes[current].next[level]].key<key)current=nodes[current].next[level];update[level]=current;}return nodes[current].next[0];}
fn bool contains(Node* nodes,int active,long key){int[MAX_LEVELS] update;int found=find_update(nodes,active,key,&update[0]);return found!=0&&nodes[found].key==key;}
fn void insert(Node* nodes,int* next,int* active,uint* rng,long key){int[MAX_LEVELS] update;find_update(nodes,*active,key,&update[0]);int height=random_level(rng);if(height>*active){for(int level=*active;level<height;level++)update[level]=0;*active=height;}int id=*next;*next+=1;nodes[id].key=key;nodes[id].value=key;nodes[id].level=height;for(int level=0;level<height;level++){nodes[id].next[level]=nodes[update[level]].next[level];nodes[update[level]].next[level]=id;}}
fn bool erase(Node* nodes,int active,long key){int[MAX_LEVELS] update;int found=find_update(nodes,active,key,&update[0]);if(found==0||nodes[found].key!=key)return false;for(int level=0;level<active;level++)if(nodes[update[level]].next[level]==found)nodes[update[level]].next[level]=nodes[found].next[level];return true;}
fn long skip_list_unique_key_set(long* input,usz length,char* output,usz capacity) @export("skip_list_unique_key_set"){
    if(input==null||length<1||input[0]<0||input[0]>(long)MAX_OPS||length!=1+2*(usz)input[0])return -1;
    usz ops=(usz)input[0];for(usz i=0;i<ops;i++){long op=input[1+2*i],key=input[2+2*i];if(op<0||op>2||key<MIN_KEY||key>MAX_KEY)return -1;}
    Node[MAX_OPS+1] nodes;for(int i=0;i<MAX_OPS+1;i++){nodes[i].key=0;nodes[i].value=0;nodes[i].level=0;for(int level=0;level<MAX_LEVELS;level++)nodes[i].next[level]=0;}
    int next=1,active=1;uint rng=0x9e3779b9;
    for(usz i=0;i<ops;i++){long op=input[1+2*i],key=input[2+2*i];if(op==0){if(contains(&nodes[0],active,key))return -1;insert(&nodes[0],&next,&active,&rng,key);}else if(op==1){_ = contains(&nodes[0],active,key);}else if(!erase(&nodes[0],active,key))return -1;}
    usz count=0;for(int id=nodes[0].next[0];id!=0;id=nodes[id].next[0])count++;
    usz required=count*8;if(output==null||capacity<required)return -2;
    usz index=0;for(int id=nodes[0].next[0];id!=0;id=nodes[id].next[0]){ulong bits=(ulong)nodes[id].value;for(usz byte=0;byte<8;byte++)output[index*8+byte]=(char)(bits>>(8*byte));index++;}
    return (long)required;
}
