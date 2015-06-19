

*-----------------------------------------------------------------------------
*
*	FBltClear.s V2.2 15.2.2002
*
*	© Stephen Brookes 1997-2002
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
	include	"fblit_library/fblit_lib.i"

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



Main:
		movem.l		d2-d4,-(sp)
		
		move.l		(l_Flags,pc),d3			;d3- flags
		
		btst		#ACTIVE,d3
		beq.s		FBCOld				;--> not active, call BltClear()
		
	     	move.l 	 	a1,d2				;chip/fast
	     	move.w 		(w_FField,pc),d4
	     	bftst		d2{0:d4}
		bne.s		FBCFast				;--> fast data

	;chip data

		btst		#CPASSON,d3
		bne.s		FBCOld				;--> pass on chip

		btst		#$00,d1
		bne.s		FBCmine 			;--> do non-asynch

		btst		#CPROCESS,d3
		bne.s		FBCmine				;--> do asynch as well
		
		bra.s		FBCOld				;--> pass on

	;fast data
	
FBCFast:
		btst		#FDISCARD,d3
		bne.s		FBCX				;--> give up (discard fast)

		btst		#FPASSON,d3
		bne.s		FBCOld				;--> pass on fast

	;process
	
FBCmine:
		move.l		a6,d2				;save a6
		
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOFillMemory,a6)

		move.l		d2,a6				;recover a6
		
	;exit
	
FBCX:
		movem.l		(sp)+,d2-d4
		rts

	;exit via BltClear()		
	
FBCOld:
		movem.l		(sp)+,d2-d4
		move.l		(l_OldBltClear,pc),-(sp)
		rts
