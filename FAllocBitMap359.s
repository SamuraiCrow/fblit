

*-----------------------------------------------------------------------------
*
*	FAllocBitMap.s V3.59 10.04.2001
*
*	© Stephen Brookes 1997-99
*
*	AllocBitMap replacement
*
*-----------------------------------------------------------------------------
*
* Input:		- 	d0.l SizeX
*				d1.l SizeY
*				d2.l Depth
*				d3.l Flags
*				a0*bitmap Friend
*
* Output:		-	d0*bitmap
*
* Trashed:		-
*
*-----------------------------------------------------------------------------



*Task list structure... signalsemaphore.SS_SIZE,ptrlist.2l(null terminated)(,strlist.2l
*			,ptrlist.2l,pattrnlist.2l)
*task log structure...  signalsemaphore.SS_SIZE,loglist.List



	include	"lvo/graphics_lib.i"
	include	"lvo/dos_lib.i"
	include	"lvo/exec_lib.i
	
	include	"graphics/gfx.i"
	include "graphics/gfxbase.i"
	
	include	"exec/memory.i"
	include	"exec/tasks.i"
	include	"exec/nodes.i"
	include	"exec/semaphores.i"
	
	include	"dos/dosextens.i"
	
	machine MC68030


ABMEntry:	bra.s		ABMap				;AllocBitMap entry


w_Pad0		dc.w	0
l_OldABMap	dc.l	0					;*AllocBitMap
l_AllocCnt	dc.l	0					;counter
l_HitCnt	dc.l	0
l_IncList	dc.l	0					;task list (inc)
l_ExcList	dc.l	0					;task list (exc)
l_User1		dc.l	0
l_LogList	dc.l	0					;task log
l_Flags		dc.l	0
l_DosBase	dc.l	0
l_FBlitBase	dc.l	0	

ACTIVE			equ	1
INCLUDE			equ	2
EXCLUDE			equ	3
LOGGING			equ	4
ANON			equ	5
DISPLAYABLE		equ	6
MEMFANY			equ	7

LOG_SIZE		equ	$100

LOCSTR			equ	$c0				;max name length

PATBUFF			equ	$1000				;sizeof pattern buffer

MAGIC			equ	$805c



	;AllocBitMap patch
	
ABMap:		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		ABMapfx1
		
ABMapBomb:	move.l		(l_OldABMap,pc),-(sp)
		rts
		
ABMapfx1:
		btst		#DISPLAYABLE,(l_Flags+3,pc)
		bne.s		ABMapfx2			;--> promote displayable!

		btst		#BMB_DISPLAYABLE,d3
		bne.s		ABMapBomb
ABMapfx2:		
		movem.l		d0-d7/a0-a5,-(sp)		;store reg's
		move.l		a6,a5				;a5- gfxbase
		move.l		(gb_ExecBase,a6),a6
		
		sub.l		a1,a1
		jsr		(_LVOFindTask,a6)
		move.l		d0,a1				;a1- *task
		
		bsr		FindName			;a2- name,d1-len
		subq.l		#$01,d1
		bpl.s		ABName				;--> named task
		
ABNoName:	btst		#ANON,(l_Flags+3,pc)
		beq		ABMapnorm1			;--> exclude anon
		bra.s		ABFast				;--> promote anon
		
ABName:		lea		(l_IncList,pc),a0		;which list
		btst		#EXCLUDE,(l_Flags+3,pc)
		beq.s		ABMaps1				;--> include mode
		
		lea		(l_ExcList,pc),a0
ABMaps1:	move.l		(a0),a0				;a0- list
		tst.l		a0
		beq.s		ABBadList			;--> no list (duh!)
		
		move.l		(SS_SIZE,a0),a3			;a3- pointer list	
		tst.l		a3
		beq.s		ABBadList			;--> no entries
		
ABListl1:	move.l		(a3)+,a4			;next string
		tst.l		a4
		beq.s		ABBadList			;--> no string
		move.l		d1,d0				;d0- last char

ABListl2:	move.b		(a2,d0.w),d2
		cmp.b		#'Z',d2
		bgt.s		cconv0
		cmp.b		#'A',d2
		blt.s		cconv0
		add.b		#$20,d2
cconv0:		move.b		(a4,d0.w),d3
		cmp.b		#'Z',d3
		bgt.s		cconv1
		cmp.b		#'A',d3
		blt.s		cconv1
		add.b		#$20,d3
cconv1:		cmp.b		d2,d3		
		bne.s		ABListl1			;--> no match
		dbra		d0,ABListl2
		
		tst.b		(1,a4,d1.w)
		bne.s		ABListl1			;--> different length
		
		
		

ABGoodList:	btst		#EXCLUDE,(l_Flags+3,pc)
		bne.s		ABMapnorm1			;--> exclude listed		
		
	;	
	;include
	;
	
ABFast:	
		move.l		a5,a6				;restore gfxbase
		movem.l		(sp),d0-d7/a0-a5		;restore reg's
		
		move.l		#MEMF_FAST,d7			;default...
		btst		#MEMFANY,(l_Flags+3,pc)
		beq.s		ABFasts1			;--> use deafault
		
		move.l		#MEMF_ANY,d7
ABFasts1:	
		or.l		#MEMF_PUBLIC,d7			;force MEMF_PUBLIC
		
		bsr		myallocbm
		
		lea		(l_HitCnt,pc),a5
		addq.l		#$01,(a5)
		
		addq.l		#$04,sp
		movem.l		(sp)+,d1-d7/a0-a5
		rts






ABBadList:	bsr.s		LogTask				;add to log (a2=name,d1=len)
		btst		#EXCLUDE,(l_Flags+3,pc)
		bne.s		ABFast				;--> include unlisted

	;
	;exclude
	;
	
ABMapnorm1:	lea		(l_AllocCnt,pc),a0
		addq.l		#$01,(a0)
				
ABMapnorm:	move.l		a5,a6				;restore gfxbase
		movem.l		(sp)+,d0-d7/a0-a5		;restore reg's
		move.l		(l_OldABMap,pc),-(sp)
		rts
		
		
		
		
		
	;
	;log task name
	;		
	
LogTask:	btst		#LOGGING,(l_Flags+3,pc)
		beq.s		ltxx

		movem.l		d0-d7/a0-a6,-(sp)		;save stuff
		move.l		a2,a5
		move.l		d1,d7
		bmi.s		ltx				;no name
		
		jsr		(_LVOForbid,a6)
		move.l		(l_LogList,pc),a0
		tst.l		a0
		beq.s		ltexit				;--> no log list
		
		lea		(SS_SIZE,a0),a4			;a4- List
		
		move.l		#LOG_SIZE,d0			;get memory
		moveq		#MEMF_PUBLIC,d1
		jsr		(_LVOAllocVec,a6)
		tst.l		d0
		beq.s		ltexit				;no mem
		
		move.l		d0,a2				;a2- Node
		add.l		#LN_SIZE,d0
		move.l		d0,(LN_NAME,a2)			;set name pntr
		
		move.l		d0,a1				;a1- name$

		clr.b		(1,a1,d7.w)			;ensure null termination
		
ltl1:		move.b		(a5,d7.w),(a1,d7.w)		;copy string
		dbra		d7,ltl1
		
		move.l		a4,a0				;allready logged?
		move.l		a2,a5				;save node
		jsr		(_LVOFindName,a6)
		tst.l		d0
		beq.s		lts0
		
		move.l		a5,a1				;free mem
		jsr		(_LVOFreeVec,a6)
		bra.s		ltexit
		
lts0:		move.l		a4,a0				;list
		move.l		a5,a1				;node
		jsr		(_LVOAddTail,a6)		;add node

ltexit:		jsr		(_LVOPermit,a6)

ltx:		movem.l		(sp)+,d0-d7/a0-a6
ltxx:		rts
		
		
		
		
		
	;
	;get task name
	;			
		
FindName:	moveq		#0,d1
		
		move.l		(LN_NAME,a1),a2
		tst.l		a2
		beq.s		fns0				;no task name
		
fnl1:		tst.b		(a2,d1.w)			;task name len
		beq.s		fns0
		addq.l		#$01,d1
		cmp.l		#LOCSTR,d1
		bne.s		fnl1
		
fns0:		cmp.b		#NT_PROCESS,(LN_TYPE,a1)	;process
		bne.s		fnx

		tst.l		(pr_TaskNum,a1)
		beq.s		strip
		
		move.l		(pr_CLI,a1),d0			;backgrounnd cli
		beq.s		strip
		lsl.l		#$02,d0
		move.l		d0,a0
		
		move.l		(cli_CommandName,a0),d0
		beq.s		fnx
		lsl.l		#$02,d0
		move.l		d0,a0		

		moveq		#0,d0
		move.b		(a0)+,d0			;string length
		beq.s		fnx
		
		move.l		d0,d1
		move.l		a0,a2
		
strip:		move.l		d1,d0
		move.l		a2,a0
		subq.l		#$01,d0
		
strip0:		cmp.b		#':',(d0.l,a0)
		beq.s		strip1
		cmp.b		#'/',(d0.l,a0)
		beq.s		strip1
		dbra		d0,strip0
		
strip1:		addq.w		#$01,d0
		add.l		d0,a2
		sub.l		d0,d1
		
		move.l		#LOCSTR,d0			;max len
		cmp.l		d1,d0
		bcc.s		fnx
		move.l		d0,d1

fnx:		rts



*-----------------------------------------------------------------------------
*
* Input:		- 	d0.l SizeX
*				d1.l SizeY
*				d2.l Depth
*				d3.l Flags
*				d7.l memory attributes
*				a0*bitmap Friend
*
* Output:		-	d0*bitmap
*
* Trashed:		-
*
*-----------------------------------------------------------------------------

		
myallocbm:
		
	;clean up parameters
	
		and.l		#$ffff,d0
		and.l		#$ffff,d1
		and.l		#$ff,d2		
		move.l		d7,-(sp)

	;deal with friend bitmap
	
		tst.l		a0
		beq.s		mabms0				;--> no friend
		
		cmp.b		(bm_Depth,a0),d2
		bne.s		mabms0				;--> not same depth
		
		cmp.w		#MAGIC,(bm_Pad,a0)
		bne.s		mabms0				;--> friend not interleaved
		
		bset		#BMB_INTERLEAVED,d3		;make allocation interleaved too
		
	;allocate bitmap structure
			
mabms0:
		move.l		a6,a5				;a5- gfxbase
		move.l		(gb_ExecBase,a5),a6		;a6- execbase
		
		move.l		d0,d6				;save stuff
		move.l		d1,d7
		
		moveq		#bm_SIZEOF-8*4,d0		;basic bitmap(no planes)
		move.w		d2,d1				;d1- depth
		btst		#BMB_MINPLANES,d3
		bne.s		mabms1				;--> minplanes
		
		cmp.b		#$08,d1
		bcc.s		mabms1				;--> depth>=8
		
		moveq		#$08,d1
mabms1:
		lsl.l		#$02,d1				;d1- depth*4
		add.w		d1,d0				;d0- size
		
		move.l		#MEMF_CLEAR|MEMF_PUBLIC,d1
		jsr		(_LVOAllocVec,a6)
		move.l		d0,a4				;a4- bitmap
		
		tst.l		d0
		beq		mabmexit			;--> no memory
		
	;allocate planes (d6-sizex,d7-sizey,d2-depth,d3-flags,a4-bitmap)
		
		move.w		d7,(bm_Rows,a4)			;set rows
		move.b		d2,(bm_Depth,a4)		;set depth
		
		moveq		#$0f,d0				;d0- plane alignment (16bit)
		btst		#BMB_DISPLAYABLE,d3
		beq.s		mabms2				;--> not-displayable		
		
		move.l		#$3f,d0				;d0- plane alignment (64bit)
mabms2:
		add.w		d0,d6				
		not.w		d0
		and.w		d0,d6
		lsr.w		#$03,d6
	
	;interleaved

		btst		#BMB_INTERLEAVED,d3
		beq.s		mabms4				;--> not interleaved	
		
		cmp.b		#$02,d2
		bcs.s		mabms4				;--> too shallow for interleave
	
		cmp.w		#$ffd,d7
		bgt.s		mabms4				;--> too big
		
		cmp.w		#$ffd,d6
		bgt.s		mabms4				;--> too big
		
		move.w		d6,d0				;d0- bpr
		and.l		#$ffff,d7
		mulu.w		d2,d0
		mulu.l		d7,d0				;d0- total planes size
		
		move.l		(sp),d1				;fetch memory attributes
		btst		#BMB_CLEAR,d3
		beq.s		mabms3				;--> don't clear planes
		
		or.l		#MEMF_CLEAR,d1
mabms3:		
		jsr		(_LVOAllocMem,a6)
		
		tst.l		d0
		beq.s		mabms4				;--> no memory (try individual planes)
		
		move.w		d6,d1
		mulu.w		d2,d1
		move.w		d1,(bm_BytesPerRow,a4)		;modify bpr for interleave

		subq.w		#$01,d2
		moveq		#$00,d5
mabml0:		
		move.l		d0,(bm_Planes,d5.l*4,a4)
		add.l		d6,d0
		addq.l		#$01,d5
		dbra		d2,mabml0			;fill out plane pointers
		
		move.w		#MAGIC,(bm_Pad,a4)
		bra.s		mabmexit			;--> all done
		
	;non-interleaved		
	
mabms4:
		move.w		d6,(bm_BytesPerRow,a4)
		mulu.w		d6,d7				;d7- plane size
		
		move.l		(sp),d4				;d4- mem attributes
		btst		#BMB_CLEAR,d3
		beq.s		mabms5				;--> don't clear planes
		
		or.l		#MEMF_CLEAR,d4
mabms5:
		subq.w		#$01,d2
		moveq		#$00,d5				;d5- plane counter
mabml1:
		move.l		d7,d0
		move.l		d4,d1
		jsr		(_LVOAllocMem,a6)
		
		move.l		d0,(bm_Planes,d5.l*4,a4)
		beq.s		mabms6				;--> no memory
		
		addq.l		#$01,d5
		dbra		d2,mabml1
		
		bra.s		mabmexit			;--> all done
mabml2:
		move.l		(bm_Planes,d5.l*4,a4),a1
		move.l		d7,d0
		jsr		(_LVOFreeMem,a6)		
mabms6:
		dbra		d5,mabml2
		
	;exit stuff
		
mabmexitbad:
		move.l		a4,a1
		jsr		(_LVOFreeVec,a6)
		sub.l		a4,a4				
mabmexit:
		move.l		a5,a6				;restore gfxbase
		move.l		a4,d0				;d0- bitmap (maybe)
		addq.l		#$04,sp
		rts		
				
		
		
