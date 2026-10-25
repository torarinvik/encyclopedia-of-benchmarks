/* Independent bounded reimplementation of Stanford Puzzle (Forest Baskett).
   The pinned source has no explicit redistribution grant; no source code or
   source comments are copied into this port. See the package README. */
#include <stddef.h>
#include <stdint.h>

#define SIDE 5
#define CELL_COUNT 125
#define TYPE_COUNT 13
#define MAX_PASSES 100
#define MAX_SEARCH_CALLS 2005
#define SOURCE_HOLE_SCALE INT64_C(1000000)

typedef struct { int x, y, z, piece_class; } Piece;

static const Piece pieces[TYPE_COUNT] = {
    {4,2,1,0}, {2,1,4,0}, {1,4,2,0}, {2,4,1,0}, {4,1,2,0}, {1,2,4,0},
    {3,1,1,1}, {1,3,1,1}, {1,1,3,1}, {2,2,1,2}, {2,1,2,2}, {1,2,2,2},
    {2,2,2,3}
};

static int fits(const uint8_t *board, int start, int type) {
    int x0=start%SIDE, y0=(start/SIDE)%SIDE, z0=start/(SIDE*SIDE);
    Piece p=pieces[type];
    if (x0+p.x>SIDE || y0+p.y>SIDE || z0+p.z>SIDE) return 0;
    for (int z=0;z<p.z;z++) for (int y=0;y<p.y;y++) for (int x=0;x<p.x;x++)
        if (board[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x]) return 0;
    return 1;
}

static void mark(uint8_t *board, int start, int type, uint8_t occupied) {
    int x0=start%SIDE, y0=(start/SIDE)%SIDE, z0=start/(SIDE*SIDE);
    Piece p=pieces[type];
    for (int z=0;z<p.z;z++) for (int y=0;y<p.y;y++) for (int x=0;x<p.x;x++)
        board[(z0+z)*SIDE*SIDE+(y0+y)*SIDE+x0+x]=occupied;
}

static int first_empty(const uint8_t *board, int from) {
    for (int i=from;i<CELL_COUNT;i++) if (!board[i]) return i;
    return 0;
}

static int64_t source_index(int flat) {
    int x=flat%SIDE, y=(flat/SIDE)%SIDE, z=flat/(SIDE*SIDE);
    return (int64_t)(x+1)+8*(int64_t)(y+1)+64*(int64_t)(z+1);
}

static int search(uint8_t *board, int *remaining, int start,
                  int *calls, int *overflow) {
    if (++*calls>MAX_SEARCH_CALLS) { *overflow=1; return 0; }
    for (int type=0;type<TYPE_COUNT;type++) {
        int cls=pieces[type].piece_class;
        if (remaining[cls]==0 || !fits(board,start,type)) continue;
        mark(board,start,type,1);
        --remaining[cls];
        int next=first_empty(board,start);
        int child=search(board,remaining,next,calls,overflow);
        if (*overflow) return 0;
        if (child || next==0) return 1;
        ++remaining[cls];
        mark(board,start,type,0);
    }
    return 0;
}

int64_t stanford_puzzle(const int64_t *input, size_t length) {
    if (input==NULL || length!=1 || input[0]<1 || input[0]>MAX_PASSES) return -1;
    int64_t checksum=0;
    for (int64_t pass=0;pass<input[0];pass++) {
        uint8_t board[CELL_COUNT]={0};
        int remaining[4]={13,3,1,1};
        if (!fits(board,0,0)) return -1;
        mark(board,0,0,1);
        --remaining[0];
        int initial_hole=first_empty(board,0);
        int calls=0,overflow=0;
        if (initial_hole==0 || !search(board,remaining,initial_hole,&calls,&overflow) || overflow) return -1;
        checksum+=source_index(initial_hole)*SOURCE_HOLE_SCALE+calls;
    }
    return checksum;
}
