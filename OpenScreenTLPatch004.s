

*-----------------------------------------------------------------------------
*
*	OpenScreenTagListPatch.s V0.4 27.03.99
*
*-----------------------------------------------------------------------------
*
* Input:		a0- *newscreen
*			a1- *taglist
*	
* Output:		d0- *screen
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


	include "graphics/gfx.i"
	include "graphics/rastport.i"
	include "graphics/gfxbase.i"
	include	"graphics/clip.i"
	
	include	"intuition/screens.i"

	include "lvo/graphics_lib.i"
	include "lvo/exec_lib.i"
	include "lvo/layers_lib.i"
	include	"lvo/intuition_lib.i"
	include	"lvo/utility_lib.i"
	include	"fblit_library/fblit_lib.i"
	
	include	"fblit_library/fblitbase.i"

	include "exec/memory.i"

	include "hardware/custom.i"
	include blitem/be_custom.i

	machine MC68030


Entry:		bra.s		Main


w_FField	dc.w	0					;non-Chip range
l_OldOpenScreen	dc.l	0
l_FastCnt	dc.l	0					;counter
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_BlitEm	dc.l	0
l_Pad2		dc.l	0
l_Pad3		dc.l	0
l_Flags		dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0
		
	
PF_ACTIVATED		equ		1	
	

Main:
		btst		#PF_ACTIVATED,(l_Flags+3,pc)
		beq.s		OSPxx				;--> inactive		
		
		movem.l		d1/a0/a1/a6,-(sp)
		
		tst.l		a1
		beq.s		OSPTLs0				;--> no tags
		
		move.l		(l_FBlitBase,pc),a6
		move.l		(fbl_UtilityBase,a6),a6
		move.l		a1,a0
		move.l		#SA_BitMap,d0
		jsr		(_LVOFindTagItem,a6)
		tst.l		d0
		beq.s		OSPTLs0				;--> no #SA_BitMap tag
	
		move.l		(4,d0.l),d0
		bne.s		OSPTLs1				;--> d0- *bitmap
OSPTLs0:		
		move.l		(4,sp),a0
		tst.l		a0
		beq.s		OSPx				;--> no *newscreen
		
		move.w		(ns_Type,a0),d0
		btst		#$06,d0
		beq.s		OSPx				;--> no CUSTOMBITMAP
	
		move.l		(ns_CustomBitMap,a0),d0
		beq.s		OSPx				;--> Duh!
OSPTLs1:
		bsr.s		OSPcb				;<--> clone chip bmp
		
		tst.l		d0
		beq.s		OSPbadx				;--> no chip bitmap
OSPx:		
		movem.l		(sp)+,d1/a0/a1/a6
OSPxx:		
		move.l		(l_OldOpenScreen,pc),-(sp)
		rts
OSPbadx:
		movem.l		(sp)+,d1/a0/a1/a6
		moveq		#$00,d0		
		rts		
		



	;
	;move fast bitmap to chip (d0- *bitmap, returns d0-0 for failure)
	;

OSPcb:
		movem.l		d2-d7/a2-a5,-(sp)
		
		move.l		(l_FBlitBase,pc),a6
		move.l		d0,a0				;a0- *bitmap
		moveq		#-1,d1
		jsr		(_LVOTypeOfBitMap,a6)
		move.l		a6,a5				;a5- fblitbase
		tst.l		d0
		beq		OSPcbgoodx			;--> chip bitmap
		
		move.l		(fbl_GraphicsBase,a5),a6
		move.l		a0,a4				;a4- source bitmap
		
		move.l		#BMA_HEIGHT,d1
		jsr		(_LVOGetBitMapAttr,a6)
		move.l		d0,d5				;d5- sizey
		
		move.l		a4,a0
		move.l		#BMA_DEPTH,d1
		jsr		(_LVOGetBitMapAttr,a6)
		move.l		d0,d6				;d6- depth
		beq		OSPcbgoodx			;--> no planes
		
		move.l		a4,a0
		move.l		#BMA_FLAGS,d1
		jsr		(_LVOGetBitMapAttr,a6)
		move.l		d0,d3
		bset		#BMB_DISPLAYABLE,d3		;d3- flags (|BMF_DISPLAYABLE)
		
		move.l		a4,a0
		move.l		#BMA_WIDTH,d1
		jsr		(_LVOGetBitMapAttr,a6)
		move.l		d0,d4				;d4- sizex
		
		move.l		d5,d1				;d1- height
		move.l		d6,d2				;d2- depth
		sub.l		a0,a0				;a0- friend
		jsr		(_LVOAllocBitMap,a6)
		move.l		d0,a3				;a3- dest bitmap
		beq.s		OSPcbbadx
		
		move.l		a4,a0				;a0- source bitmap
		move.l		a3,a1				;a1- dest bitmap
		moveq		#$00,d0				;d0- srcx
		moveq		#$00,d1				;d1- srcy
		moveq		#$00,d2				;d2- dstx
		moveq		#$00,d3				;d3- dsty
		move.l		#$c0,d6				;d6- minterm
		moveq		#-1,d7
		jsr		(_LVOBltBitMap,a6)
		jsr		(_LVOWaitBlit,a6)
		
		move.l		(a4),d0
		move.l		(a3),d1
		move.l		(4,a4),d2
		move.l		(4,a3),d3
		move.l		d0,(a3)
		move.l		d1,(a4)
		move.l		d2,(4,a3)
		move.l		d3,(4,a4)
		
		swap		d3
		extb.l		d3
		subq.l		#$01,d3
OSPl1:
		move.l		(d3*4,bm_Planes,a3),d0
		move.l		(d3*4,bm_Planes,a4),d1
		move.l		d0,(d3*4,bm_Planes,a4)
		move.l		d1,(d3*4,bm_Planes,a3)
		
		dbra		d3,OSPl1
		
		move.l		a3,a0
		jsr		(_LVOFreeBitMap,a6)
OSPcbgoodx:		
		movem.l		(sp)+,d2-d7/a2-a5
		moveq		#-1,d0
		rts		
OSPcbbadx:
		movem.l		(sp)+,d2-d7/a2-a5
		moveq		#$00,d0
		rts		



		
		