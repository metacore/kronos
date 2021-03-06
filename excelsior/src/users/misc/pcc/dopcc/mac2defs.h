/* VAX-11/780 Registers */

 /* scratch registers */
# define R0 0
# define R1 1
# define R2 2
# define R3 3
# define R4 4
# define R5 5

 /* register variables */
# define R6 6
# define R7 7
# define R8 8
# define R9 9
# define R10 10
# define R11 11

 /* special purpose registers */
# define AP 12 /* argument pointer */
# define FP 13 /* frame pointer */
# define SP 14 /* stack pointer */
# define PC 15 /* program counter */

 /* floating registers */

 /* there are no floating point registers on the VAX */

extern int fregs;
extern int maxargs;

# define BYTEOFF(x) ((x)&03)
# define wdal(k) (BYTEOFF(k)==0)
# define BITOOR(x) ((x)>>3)  /* bit offset to oreg offset */

# define REGSZ 16

# define TMPREG FP

/* SS. double indexing not available on Kronos */
# undef R2REGS   /* permit double indexing */

# define STOARG(p)     /* just evaluate the arguments, and be done with it... */
# define STOFARG(p)
# define STOSTARG(p)

# define genfcall(a,b) gencall(a,b)

# define NESTCALLS

 /* SS. 30.apr.86  do not perform VAX oriented tree transformations, */
 /*  but myreader() must be included ( the reason is func canon() ) */

# define MYREADER(p) myreader(p)

int optim2();

# define special(a, b) 0
