

*-----------------------------------------------------------------------------
*
*	FBltClear.s V2.1 20.9.2001
*
*	© Stephen Brookes 1997-2001
*
*	BltClear replacement using 020+ code and allowing blits
*	outside chip RAM.
*
*-----------------------------------------------------------------------------
*
* Input:		d0=ByteCnt.l
*			d1=Flags.l
*			a1=*MemBlock
*
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


	include "graphics/graphics_lib.i"

	machine MC68030


Entry:		bra.s		Main


w_FField	dc.w	0					;non-Chip range
l_OldBltClear	dc.l	0					;*BltClear
l_FastCnt	dc.l	0					;counters
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_Pad1		dc.l	0
l_Pad2		dc.l	0
l_Pad3		dc.l	0
l_Flags 	dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0

ACTIVE			equ	1				;patch activation
CPASSON 		equ	2				;pass all chip
CPASSASY		equ	3				;pass asynch chip
CPROCESS		equ	4				;process all chip
FPASSON 		equ	5				;pass on fast!!!
FPROCESS		equ	6				;process fast
FDISCARD		equ	7				;discard fast



Main:		movem.l 	d2-d7/a1/a5,-(sp)		;store reg's

		move.l		(l_Flags,pc),d3
		btst		#ACTIVE,d3			;patch active
		beq		OldBC				;no...

	     	move.l 	 	a1,d2				;chip/fast
	     	move.w 		(w_FField,pc),d7
	     	bftst		d2{0:d7}
		bne.s		FBCFast

		btst		#CPASSON,d3			;pass all chip?
		bne.s		DoOldBC

		btst		#$00,d1 			;wait?
		bne.s		FBCmine 			;yes, I'll do it.

		btst		#CPROCESS,d3			;do asynch too?
		bne.s		FBCmine

DoOldBC:	lea		(l_PassCnt,pc),a5
		addq.l		#$01,(a5)
		bra		OldBC

FBCFast:	btst		#FDISCARD,d3			;discard fast?
		bne		GoodExit

		lea		(l_FastCnt,pc),a5
		addq.l		#$01,(a5)

		btst		#FPASSON,d3			;pass on fast?
		bne.s		DoOldBC


	;get number of bytes to init

FBCmine:	lea		(l_ProcCnt,pc),a5
		addq.l		#$01,(a5)

	      ;  move.l 	 d0,d2
	      ;  bclr		 #$00,d2			 ;NO BYTES
		moveq		#-2,d2
		and.l		d0,d2

		btst		#$01,d1 			;flag bit 1
		beq.s		FBCs0				;0-d0=#bytes

		move.w		d2,d3				;1-d0=rows:bytes
		swap		d2
		mulu.w		d3,d2



	;get init state

FBCs0:		moveq		#0,d3
		btst		#$02,d1 			;flag bit 2
		beq.s		FBCs1				;0-clear

		move.l		d1,d3				;1-hi flag word
		swap		d1
		move.w		d1,d3
		swap		d1



	;do the deed

FBCs1:	
		jsr		(_LVOOwnBlitter,a6)
		jsr		(_LVOWaitBlit,a6)

		move.l		a1,d4
		bclr		#$00,d4 			;NO BYTES
		move.l		d4,a1
		btst		#$01,d4 			;odd word?
		beq.s		FBCs2				;no

		subq.l		#$02,d2 			;lw align addr
		bcs.s		DisBlitX			;(nothing to do!)
		move.w		d3,(a1)+

	;by now the addr is lw aligned, so any odd word in #bytes gets ignored until
	;the end...
	;NOTE: there may be nothing to do!!!

FBCs2:		move.l		d3,d4
		move.l		d3,d5
		move.l		d3,d6

		lsr.l		#$02,d2 			;bytes to longs
		subx.l		d7,d7				;d4-odd word flag

		lea		(a1,d2.l*4),a1			;go to end
		move.l		a1,a5				;save end

	;any longs?

		lsr.l		#$01,d2
		bcc.s		FBCs3

		move.l		d3,-(a1)

	;any quads?

FBCs3:		lsr.l		#$01,d2
		bcc.s		FBCs4

		movem.l 	d3-d4,-(a1)

	;any octets?

FBCs4:		lsr.l		#$01,d2
		bcc.s		FBCs5

		movem.l 	d3-d6,-(a1)

	;finish sixteens

FBCs5:		subq.l		#$01,d2
		bmi.s		FBCs6

FBCl0:		movem.l 	d3-d6,-(a1)
		movem.l 	d3-d6,-(a1)
	        subq.l		#$01,d2
	        bpl.s		FBCl0
;		dbf		d2,FBCl0

	;clean up (odd word)

FBCs6:		tst.l		d7
		beq.s		DisBlitX

		move.w		d3,(a5)+
		bra.s		DisBlitX



	;do old bltclear

OldBC:		move.l		(l_OldBltClear,pc),a5
		jsr		(a5)
		bra.s		GoodExit




	;
	;exit stuff
	;


DisBlitX:	
		jsr		(_LVODisownBlitter,a6)

BadExit:

GoodExit:	movem.l 	(sp)+,d2-d7/a1/a5		;restore reg's

Exit:		rts




