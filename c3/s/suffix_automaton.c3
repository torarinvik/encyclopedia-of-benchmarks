module suffix_automaton;

const usz MAX_TEXT = 256;
const usz MAX_QUERIES = 128;
const usz MAX_STATES = 2 * MAX_TEXT;
const usz MAX_INPUT_LENGTH = 33283;
const usz MAX_VALID_INPUT_LENGTH = 33282;
const usz ALPHABET = 128;

struct SamState { int length; int link; int[ALPHABET] next; }

void initialize_state(SamState* states, int index) {
    states[index].length=0;states[index].link=-1;
    for(int symbol=0;symbol<128;symbol++)states[index].next[symbol]=-1;
}
int build_automaton(SamState* states,int* text,int text_length) {
    initialize_state(states,0);int state_count=1,last=0;
    for(int position=0;position<text_length;position++){
        int symbol=text[position],current=state_count++;initialize_state(states,current);states[current].length=states[last].length+1;int previous=last;
        while(previous!=-1&&states[previous].next[symbol]==-1){states[previous].next[symbol]=current;previous=states[previous].link;}
        if(previous==-1)states[current].link=0;
        else{int next_state=states[previous].next[symbol];if(states[previous].length+1==states[next_state].length)states[current].link=next_state;
            else{int clone=state_count++;initialize_state(states,clone);states[clone].length=states[previous].length+1;states[clone].link=states[next_state].link;for(int c=0;c<128;c++)states[clone].next[c]=states[next_state].next[c];
                while(previous!=-1&&states[previous].next[symbol]==next_state){states[previous].next[symbol]=clone;previous=states[previous].link;}states[next_state].link=clone;states[current].link=clone;}}
        last=current;
    }
    return state_count;
}
int contains_pattern(SamState* states,int* pattern,int length){int current=0;for(int i=0;i<length;i++){current=states[current].next[pattern[i]];if(current==-1)return 0;}return 1;}
long count_occurrences(SamState* states,int state_count,int* text,int text_length,int* pattern,int pattern_length){
    int current=0;for(int i=0;i<pattern_length;i++){current=states[current].next[pattern[i]];if(current==-1)return 0;}
    int[MAX_STATES] occurrences=zeroed;int[MAX_TEXT+1] by_length=zeroed;int[MAX_STATES] order=zeroed;
    for(int state=0;state<state_count;state++)by_length[states[state].length]++;
    for(int length=1;length<=text_length;length++)by_length[length]+=by_length[length-1];
    for(int state=state_count-1;state>=0;state--)order[--by_length[states[state].length]]=state;
    int last=0;for(int i=0;i<text_length;i++){last=states[last].next[text[i]];occurrences[last]=1;}
    for(int i=state_count-1;i>=0;i--){int state=order[i];if(states[state].link!=-1)occurrences[states[state].link]+=occurrences[state];}
    return (long)occurrences[current];
}
long count_distinct_substrings(SamState* states,int state_count){long total=0;for(int state=1;state<state_count;state++)total+=states[state].length-states[states[state].link].length;return total;}
void store_i64_le(char* output,usz offset,long value){ulong bits=@bitcast(ulong,value);for(usz byte=0;byte<8;byte++)output[offset+byte]=(char)(bits>>(8*byte));}

fn long suffix_automaton(long* input,usz length,char* output,usz capacity) @export("suffix_automaton") {
    if(input==null||length<2||length>MAX_INPUT_LENGTH)return -1;
    if(input[0]<1||input[0]>(long)MAX_TEXT)return -1;
    int text_length=(int)input[0];usz query_count_index=(usz)text_length+1;
    if(length<=query_count_index||input[query_count_index]<0||input[query_count_index]>(long)MAX_QUERIES)return -1;
    int query_count=(int)input[query_count_index];if(length>MAX_VALID_INPUT_LENGTH)return -1;
    int[MAX_TEXT] text=zeroed;
    for(int i=0;i<text_length;i++){long symbol=input[(usz)i+1];if(symbol<0||symbol>=(long)ALPHABET)return -1;text[i]=(int)symbol;}
    SamState[MAX_STATES] states=zeroed;int state_count=build_automaton(&states[0],&text[0],text_length);
    long[MAX_QUERIES] results=zeroed;u8[MAX_QUERIES] opcodes=zeroed;usz cursor=query_count_index+1;
    for(int query=0;query<query_count;query++){
        if(cursor+1>=length)return -1;long opcode_value=input[cursor++],pattern_length_value=input[cursor++];
        if(opcode_value<0||opcode_value>2||pattern_length_value<0||pattern_length_value>(long)MAX_TEXT)return -1;
        int opcode=(int)opcode_value,pattern_length=(int)pattern_length_value;if(opcode==2&&pattern_length!=0)return -1;if((usz)pattern_length>length-cursor)return -1;
        int[MAX_TEXT] pattern=zeroed;for(int i=0;i<pattern_length;i++){long symbol=input[cursor++];if(symbol<0||symbol>=(long)ALPHABET)return -1;pattern[i]=(int)symbol;}
        opcodes[query]=(u8)opcode;if(opcode==0)results[query]=(long)contains_pattern(&states[0],&pattern[0],pattern_length);else if(opcode==1)results[query]=count_occurrences(&states[0],state_count,&text[0],text_length,&pattern[0],pattern_length);else results[query]=count_distinct_substrings(&states[0],state_count);
    }
    if(cursor!=length)return -1;usz output_bytes=(usz)query_count*9;if(output==null||capacity<output_bytes)return -2;
    for(int query=0;query<query_count;query++){output[(usz)query*9]= (char)opcodes[query];store_i64_le(output,(usz)query*9+1,results[query]);}
    return (long)output_bytes;
}
