module sparse_set_dense_array;

const usz MAX_UNIVERSE = 32;
const usz MAX_OPERATIONS = 30;
const usz MAX_LENGTH = 63;

fn long sparse_set_dense_array(long* input, usz length)
        @export("sparse_set_dense_array") {
    if (input==null || length<2 || length>MAX_LENGTH) return -1;
    if (input[0]<1 || input[0]>(long)MAX_UNIVERSE
            || input[1]<0 || input[1]>(long)MAX_OPERATIONS) return -1;
    usz universe=(usz)input[0];
    usz count=(usz)input[1];
    if (length!=2+2*count) return -1;
    for (usz i=0;i<count;i++) {
        long opcode=input[2+2*i];
        long key=input[3+2*i];
        if (opcode<0 || opcode>3 || key<0 || key>=(long)universe) return -1;
        if (opcode==3 && key!=0) return -1;
    }
    int[MAX_UNIVERSE] dense;
    int[MAX_UNIVERSE] sparse;
    for (usz key=0;key<universe;key++) sparse[key]=(int)universe;
    usz size=0;
    long answers=0;
    for (usz i=0;i<count;i++) {
        int opcode=(int)input[2+2*i];
        int key=(int)input[3+2*i];
        int index=sparse[key];
        bool present=(usz)index<size && dense[index]==key;
        long status=0;
        if (opcode==0) {
            if (!present) {
                dense[size]=key;
                sparse[key]=(int)size;
                size++;
                status=1;
            }
        } else if (opcode==1) {
            if (present) {
                int last=dense[size-1];
                dense[index]=last;
                sparse[last]=index;
                size--;
                status=1;
            }
        } else if (opcode==2) {
            status=present?1:0;
        } else {
            status=size>0?1:0;
            size=0;
        }
        answers=(answers<<1)|status;
    }
    long final_mask=0;
    for (usz i=0;i<size;i++) final_mask|=(long)1<<dense[i];
    return (final_mask<<count)|answers;
}
