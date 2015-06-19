

*-----------------------------------------------------------------------------
*
*	FSetRast.s V2.4 02.01.99
*
*	© Stephen Brookes 1997-99
*
*
*-----------------------------------------------------------------------------
*
* Input:		- a1-rp,d0.b-pen
*	
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


	include	"graphics/gfx.i"
	include	"graphics/rastport.i"
	include	"graphics/clip.i"
	
	include	"lvo/graphics_lib.i"
	include	"fblit_library/fblit_lib.i"

	machine MC68030



Entry:		bra.s		Main


w_FField	dc.w	0					;non-Chip range
l_OldSetRast	dc.l	0					;*SetRast
l_FastCnt	dc.l	0					;counter
l_ProcQ		dc.l	0
l_ProcS		dc.l	0
l_PassCnt	dc.l	0
l_Debug		dc.l	0
l_Pad3		dc.l	0
l_Flags		dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0
		
ACTIVE			equ	1				;patch activation
FPASSON			equ	2				;pass on fast!!!
FDISCARD		equ	3				;discard fast
CPROCESS		equ	4				;process chip

MAGIC			equ	$805c
	

Main:		movem.l		d0-d7/a0-a5,-(sp)		;store reg's
		
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		fix0
		
		jsr		(_LVOLockLayerRom,a6)
fix0:		
		move.l		(l_Flags,pc),d2
		btst		#ACTIVE,d2
		beq		OldSR
		
		lea		(w_FField,pc),a3
		
		move.l		a6,a5
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOTypeOfRastPort,a6)
		move.l		a5,a6
		move.l		d0,d6
		move.l		(sp),d0
		tst.l		d6
		bne.s		NewSR
ChipDat:
		btst		#CPROCESS,d2			;process chip
		bne.s		ProcSR
		
OldSRCnt:	addq.l		#$01,(l_PassCnt-w_FField,a3)
		bra		OldSR		
		
NewSR:		addq.l		#$01,(l_FastCnt-w_FField,a3)
	
		btst		#FPASSON,d2
		bne		OldSRCnt
			
ProcSR:		move.l		d0,d7				;d7-pen




	;
	;do quick if possible
	;

		move.l		(rp_Layer,a1),d1
		bne.s		FullSR				;--> layers
		
		move.l		(rp_BitMap,a1),a5
		move.l		(bm_BytesPerRow,a5),d5
		swap		d5				;d5-rows:bpr
	
		cmp.w		#MAGIC,(bm_Pad,a5)
		bne.s		QuickSR				;--> not magic
		
		move.w		d5,d2				;d2-bpr
		move.l		(bm_Planes+4,a5),d1
		ext.l		d2
		sub.l		(bm_Planes,a5),d1
		cmp.l		d2,d1
		bls.s		FullSR				;--> dodgy interleave

QuickSR:	addq.l		#$01,(l_ProcQ-w_FField,a3)
		moveq		#$00,d2
		move.b		(rp_Mask,a1),d4			;d4-mask
		move.b		(bm_Depth,a5),d2		;d2-depth
		move.l		#$ffff0006,d3			;d3-fill
		subq		#$01,d2
		bmi.s		BadExit

ql0:		btst		d2,d4
		beq.s		qs1				;--> masked		
	
		moveq.l		#$02,d1
		btst		d2,d7
		beq.s		qs0				;--> clear plane
		
		move.l		d3,d1				;fill plane
		
qs0:		move.l		(bm_Planes,a5,d2.l*4),a1	;addr
		move.l		d5,d0				;size
		jsr		(_LVOBltClear,a6)
		
qs1:		dbra		d2,ql0		
		bra.s		GoodExit		





	;
	;the full monty
	;
		
FullSR:		addq.l		#$01,(l_ProcS-w_FField,a3)
		move.l		(rp_BitMap,a1),a5
		move.l		a1,a4				;save rp
		move.l		#BMA_WIDTH,d1
		move.l		a5,a0
		jsr		(_LVOGetBitMapAttr,a6)
		
		move.l		d0,d4				;d4-sizex
		move.w		(bm_Rows,a5),d5			;d5-sizey
		
		sub.l		#bm_SIZEOF,sp			;build temp bitmap
		move.l		sp,a0

		move.l		#$7ffe7ffe,(bm_BytesPerRow,a0)	;BIG bmp
		move.l		#$00080000,(bm_Flags,a0)	;no flg, 8bit, clr pad
		
		moveq.l		#$07,d2
		
PSRl1:		add.b		d7,d7
		subx.l		d3,d3
		move.l		d3,(bm_Planes,a0,d2.l*4)
		dbra		d2,PSRl1
		
		moveq		#0,d0				;srcx
		moveq		#0,d1				;srcy
		moveq		#0,d2				;dstx
		moveq		#0,d3				;dsty
		move.b		#$c0,d6				;minterm
		move.l		a4,a1
		
		jsr		(_LVOBltBitMapRastPort,a6)
				
		add.l		#bm_SIZEOF,sp			
		bra.s		GoodExit
	
	
	
		
	;	
	;do old setrast
	;
	
OldSR:		move.l		(l_OldSetRast,pc),a5
		jsr		(a5)
		
	
	
	
	;
	;get outa town
	;
	
BadExit:	
	
GoodExit:	movem.l		(sp)+,d0-d7/a0-a4		;restore reg's
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		gexit0
		
		jsr		(_LVOUnlockLayerRom,a6)	
gexit0:		
		move.l		(sp)+,a5
		rts	




