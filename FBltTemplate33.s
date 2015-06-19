

*-----------------------------------------------------------------------------
*
*	FBltTemplate.s V3.3 20.09.2001
*
*-----------------------------------------------------------------------------
*
* Input:		d0- srcx.w
*			d1- srcmod.w
*			d2- dstx.w
*			d3- dsty.w
*			d4- sizex.w
*			d5- sizey.w
*			a0- *src
*			a1- *rastport
*	
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------


	include "graphics/gfx.i"
	include "graphics/rastport.i"
	include "graphics/gfxbase.i"
	include	"graphics/clip.i"

	include "lvo/graphics_lib.i"
	include "lvo/exec_lib.i"
	include "lvo/layers_lib.i"
	include	"fblit_library/fblit_lib.i"

	include "exec/memory.i"

	include "hardware/custom.i"
;	include blitem/be_custom.i

	machine MC68030


Entry:		bra.s		Main


w_FField	dc.w	0					;non-Chip range
l_OldBltTemp	dc.l	0					;*BltMask
l_FastCnt	dc.l	0					;counter
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_BlitEm	dc.l	0
l_Pad2		dc.l	0
l_Pad3		dc.l	0
l_Flags		dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0
		
ACTIVE			equ	1				;patch activation
FPASSON			equ	2				;pass on fast!!!
FPROCESS		equ	3
FDISCARD		equ	4				;discard fast
CPROCESS		equ	5
	

Main:
		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		mfix1				;--> active
mfix0:		
		move.l		(l_OldBltTemp,pc),-(sp)
		rts	
mfix1:		
		btst		#CPROCESS,(l_Flags+3,pc)
		beq.s		CheckRP				;--> don't process chip
		
		btst		#FPROCESS,(l_Flags+3,pc)
		beq.s		CheckRP				;--> don't process fast
	
	;process fast and chip
	
		move.l		a5,-(sp)
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		fix11				;--> no layers
		
		jsr		(_LVOLockLayerRom,a6)
fix11:
		bsr		BltTemp				
		tst.l		a5
		beq.s		fix12				;--> no layers
		
		jsr		(_LVOUnlockLayerRom,a6)
fix12:
		move.l		(sp)+,a5
		rts		

	;check rastport		
		
CheckRP:		
		movem.l		d0/d1/a4/a5,-(sp)		;store reg's

		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		fix0
		
		jsr		(_LVOLockLayerRom,a6)
fix0:		
		move.w		(w_FField,pc),d1		
		move.l		a0,d0				;d0- *template
		bftst		d0{0:d1}
		bne.s		NewBM				;--> fast template
		
		move.l		a6,a5
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOTypeOfRastPort,a6)
		move.l		a5,a6
		tst.l		d0
		bne.s		NewBM				;--> fast data
ChipDat:
		movem.l		(sp)+,d0/d1
		btst		#CPROCESS,(l_Flags+3,pc)
		bne.s		Proc				;--> process chip
		
OldBMcnt:	lea		(l_PassCnt,pc),a5
		addq.l		#$01,(a5)

		move.l		a1,a4
		move.l		(l_OldBltTemp,pc),a5
		jsr		(a5)
		move.l		a4,a1
		bra.s		blahexit
NewBM:
		movem.l		(sp)+,d0/d1
		lea		(l_FastCnt,pc),a5
		addq.l		#$01,(a5)
		
		btst		#FDISCARD,(l_Flags+3,pc)
		bne.s		blahexit
	
		btst		#FPASSON,(l_Flags+3,pc)
		bne		OldBMcnt
			
Proc:		lea		(l_ProcCnt,pc),a5
		addq.l		#$01,(a5)			
		bsr.s		BltTemp
blahexit:
		movem.l		(sp)+,a4
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		bes0
		
		jsr		(_LVOUnlockLayerRom,a6)
bes0:
		move.l		(sp)+,a5
		rts
		
			
	;
	;BltTemplate
	;d0-srcx.w
	;d1-srcmod.w
	;d2-dstx.w
	;d3-dsty.w
	;d4-sizex.w
	;d5-sizey.w
	;a0-template
	;a1-rastport
	;
	
BltTemp:	movem.l		d0-d5/a0/a2/a6,-(sp)
		subq.w		#$01,d4
		subq.w		#$01,d5
		and.b		#$fe,d1					;no bytes!
		move.w		d1,a2					;a2- tempmod
		move.w		d4,d1					;d1- sizex
		add.w		d2,d1					;d1- maxx
		swap		d1
		move.w		d5,d1
		add.w		d3,d1					;d1- maxx:maxy
		swap		d2
		move.w		d3,d2					;d2- minx:miny
		move.w		d0,d3
		move.l		d2,d0					;d0- minx:miny
		swap		d3					;d3- minxt:minyt
		moveq		#$00,d2
		clr.w		d3
		
		move.l		a0,d5					;no bytes
		and.b		#$fe,d5
		move.l		d5,a0
		
;		jsr		(_LVOWaitBlit,a6)
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOGetBlitter,a6)
		jsr		(_LVOTemplateRastPort,a6)
		jsr		(_LVOFreeBlitter,a6)
BltTempx:
		movem.l		(sp)+,d0-d5/a0/a2/a6
		rts		
		
		
		
		


		


		
		