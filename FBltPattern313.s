

*-----------------------------------------------------------------------------
*
*	FBltPattern.s V3.13 20.9.2001
*
*-----------------------------------------------------------------------------
*
* Input:		d0=xl.w
*			d1=yl.w
*			d2=maxx.w
*			d3=maxy.w
*			d4=bytecnt.w
*			a0=*mask.l
*			a1=*rp.l
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

	machine MC68030


_AbsExecBase		equ	4



Entry:		bra.s		Main


w_FField	dc.w	0					;non_Chip range
l_OldBltPat	dc.l	0					;*BltPat
l_FastCnt	dc.l	0					;counter
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_BlitEm	dc.l	0					;*BlitEm
l_User1		dc.l	0					;my last chance stuff
l_User2		dc.l	0					;ditto
l_Flags 	dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0


ACTIVE			equ	1				;patch activation
FPASSON 		equ	2				;pass on fast!!!
FPROCESS		equ	3				;process fast
FDISCARD		equ	4				;discard fast
CPROCESS		equ	5				;process chip
CPASSCMX		equ	6				;pass on complex (chip)




Main:
		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		mfix1				;--> active
mfix0:		
		move.l		(l_OldBltPat,pc),-(sp)
		rts	
mfix1:		
		btst		#FPROCESS,(l_Flags+3,pc)
		beq.s		CheckRP				;--> don't process fast
		
		btst		#CPROCESS,(l_Flags+3,pc)
		bne.s		profc				;--> process all chip (and fast)
		
		btst		#CPASSCMX,(l_Flags+3,pc)
		beq.s		CheckRP				;--> don't process any chip
		
		tst.l		a0
		bne.s		CheckRP				;--> don't do masked chip op's
		
		cmp.b		#$01,(rp_DrawMode,a1)
		beq.s		profc				;--> process all JAM2
		
		tst.l		(rp_AreaPtrn,a1)
		bne.s		CheckRP				;--> don't do patterned chip op's
	
	;process fast and chip (no stats, no rp check)
profc:	
		move.l		a5,-(sp)
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		fix11				;--> no layers
		
		jsr		(_LVOLockLayerRom,a6)
fix11:
		bsr		BltPat		
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
		move.l		a0,d0				;d0- *mask
		bftst		d0{0:d1}
		bne.s		NewBM				;--> fast data...
		
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
		
		btst		#CPASSCMX,(l_Flags+3,pc)
		beq.s		OldBMcnt			;--> pass on all chip
		
		tst.l		a0
		bne.s		OldBMcnt			;--> don't process masked
		
		cmp.b		#$01,(rp_DrawMode,a1)
		beq.s		Proc				;--> process JAM2 (non-masked)
		
		tst.l		(rp_AreaPtrn,a1)
		beq.s		Proc				;--> process non-patterned (non-
								;    masked, chip)		
OldBMcnt:	lea		(l_PassCnt,pc),a5
		addq.l		#$01,(a5)
		
		move.l		a1,a4
		move.l		(l_OldBltPat,pc),a5
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
		bsr.s		BltPat
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
	;BltPattern
	;d0-xl.w (top left corner)
	;d1-yl.w
	;d2-maxx.w (bottom right corner)
	;d3-maxy.w
	;d4-bytecnt.w (mask bpr)
	;a0-*mask
	;a1-*rastport
	;

BltPat:
		movem.l		d0-d3/a2/a5,-(sp)
		
		swap		d0
		move.w		d1,d0				;d0- minx:miny
		move.l		d2,d1
		swap		d1
		move.w		d3,d1				;d1- maxx:maxy
		moveq		#$00,d2				;d2- flags
		moveq		#$00,d3				;d3- minxm:minym
		move.w		d4,a2				;a2- mask bpr
		tst.l		a0			
		beq.s		BPfx1				;--> no mask
		
		swap		d1				;d1- maxy:maxx
		swap		d0				;d0- miny:minx
		add.w		#$0f,d1
		sub.w		d0,d1
		and.w		#$fff0,d1
		bgt.s		BPfx0
		
		move.w		#$10,d1
BPfx0:		
		add.w		d0,d1
		swap		d0
		subq.w		#$01,d1
		swap		d1
BPfx1:		
;		jsr		(_LVOWaitBlit,a6)
		move.l		a6,a5
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOGetBlitter,a6)
		jsr		(_LVOPatternRastPort,a6)
		jsr		(_LVOFreeBlitter,a6)
		move.l		a5,a6
		
		movem.l		(sp)+,d0-d3/a2/a5
		rts


