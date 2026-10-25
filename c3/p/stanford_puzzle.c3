// Independent bounded implementation of Stanford Puzzle, attributed by the
// pinned file to Forest Baskett. The source has no redistribution grant and
// its code and comments are not copied here; see the package README.
module stanford_puzzle;

const int SIDE = 5;
const int CELL_COUNT = 125;
const int TYPE_COUNT = 13;
const int MAX_PASSES = 100;
const int MAX_SEARCH_CALLS = 2005;
const long HOLE_SCALE = 1000000;

struct Piece { int x; int y; int z; int piece_class; }
const Piece[TYPE_COUNT] PIECES = {
    {4,2,1,0},{2,1,4,0},{1,4,2,0},{2,4,1,0},{4,1,2,0},{1,2,4,0},
    {3,1,1,1},{1,3,1,1},{1,1,3,1},{2,2,1,2},{2,1,2,2},{1,2,2,2},{2,2,2,3}
};

fn bool fits(bool* board, int start, int type) {
    int x0=start%SIDE, y0=(start/SIDE)%SIDE, z0=start/(SIDE*SIDE);
    Piece p=PIECES[type]; if (x0+p.x>SIDE || y0+p.y>SIDE || z0+p.z>SIDE) return false;
    for (int z=0;z<p.z;z++) for (int y=0;y<p.y;y++) for (int x=0;x<p.x;x++)
        if (board[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x]) return false;
    return true;
}
fn void mark(bool* board, int start, int type, bool value) {
    int x0=start%SIDE, y0=(start/SIDE)%SIDE, z0=start/(SIDE*SIDE); Piece p=PIECES[type];
    for (int z=0;z<p.z;z++) for (int y=0;y<p.y;y++) for (int x=0;x<p.x;x++)
        board[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x]=value;
}
fn int first_empty(bool* board, int from) {
    for (int i=from;i<CELL_COUNT;i++) if (!board[i]) return i;
    return 0;
}
fn long source_index(int flat) {
    int x=flat%SIDE, y=(flat/SIDE)%SIDE, z=flat/(SIDE*SIDE);
    return (long)(x+1)+8L*(long)(y+1)+64L*(long)(z+1);
}
fn bool search(bool* board, int* remaining, int start, int* calls, bool* overflow) {
    calls[0] += 1; if (calls[0]>MAX_SEARCH_CALLS) { overflow[0]=true; return false; }
    for (int type=0;type<TYPE_COUNT;type++) {
        int cls=PIECES[type].piece_class; if (remaining[cls]==0 || !fits(board,start,type)) continue;
        mark(board,start,type,true); remaining[cls] -= 1;
        int next=first_empty(board,start); bool child=search(board,remaining,next,calls,overflow);
        if (overflow[0]) return false;
        if (child || next==0) return true;
        remaining[cls] += 1; mark(board,start,type,false);
    }
    return false;
}

fn long stanford_puzzle(long* input, usz length) @export("stanford_puzzle") {
    if (input==null || length!=1 || input[0]<1 || input[0]>MAX_PASSES) return -1;
    long checksum=0;
    for (long pass=0;pass<input[0];pass++) {
        bool[CELL_COUNT] board; for (int cell=0;cell<CELL_COUNT;cell++) board[cell]=false;
        int[4] remaining={13,3,1,1};
        if (!fits(&board[0],0,0)) return -1;
        mark(&board[0],0,0,true); remaining[0] -= 1;
        int hole=first_empty(&board[0],0); int calls=0; bool overflow=false;
        if (hole==0 || !search(&board[0],&remaining[0],hole,&calls,&overflow) || overflow) return -1;
        checksum += source_index(hole)*HOLE_SCALE+calls;
    }
    return checksum;
}
