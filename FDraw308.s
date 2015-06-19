

*-----------------------------------------------------------------------------
*
*	FDraw.s V3.08 20.09.2001
*
*	© Stephen Brookes 1997-2001
*
*
*-----------------------------------------------------------------------------
*
* Input:		-
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
	
	include	"fblit_library/fblitbase.i"

	machine MC68030


Entry:		bra.s		Main


w_FField	dc.w	0					;non-Chip range
l_OldDraw	dc.l	0					;*Draw
l_FastCnt	dc.l	0					;counter
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_Pad1		dc.l	0
l_Pad2		dc.l	0
l_Pad3		dc.l	0
l_Flags		dc.l	0					;control
l_user3		dc.l	0
l_FBlitBase	dc.l	0
		
ACTIVE			equ	1				;patch activation
FPASSON			equ	2				;pass on fast!!!
FDISCARD		equ	3				;discard fast
FPROCESS		equ	4				;process fast
CPROCESS		equ	5				;process chip
CLIMP			equ	6				;process chip h only


	

Main:
		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		fix0				;--> active
		
		move.l		(l_OldDraw,pc),-(sp)
		rts
fix0:		
		movem.l		d0/d1/a0/a5/a6,-(sp)
		
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		fix01				;--> no layer
		
		jsr		(_LVOLockLayerRom,a6)
fix01:		
;		jsr		(_LVOWaitBlit,a6)
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOTypeOfRastPort,a6)
		tst.l		d0
		bne.s		NewDr				;--> not all chip
		
		
		
ChipDat:
		move.l		(l_Flags,pc),d0
		
		btst		#CPROCESS,d0
		bne.s		FDraw				;--> process all chip
		
		btst		#FB_FRST_DOT,(rp_Flags+1,a1)
		beq.s		FDraw				;--> always do frst_dot anyway
		
		btst		#CLIMP,d0
		beq.s		OldDrcnt			;--> don't do chip h
		
		cmp.w		(rp_cp_y,a1),d1
		beq.s		FDraw				;--> process horizontal
	
		
OldDrcnt:
		lea		(l_PassCnt,pc),a5
		addq.l		#$01,(a5)
		bra.s		OldDr0



NewDr:
		move.l		(l_Flags,pc),d0
		lea		(l_FastCnt,pc),a5
		addq.l		#$01,(a5)
				
		btst		#FPASSON,d0
		bne		OldDrcnt
		
		btst		#FDISCARD,d0
		bne.s		NewDrx
		

	;
	;new draw
	;
			
FDraw:
		move.l		(sp),d0
		lea		(l_ProcCnt,pc),a5
		addq.l		#$01,(a5)

		move.l		d2,-(sp)
		swap		d0
		move.w		d1,d0
		move.l		d0,d1				;d1- bx:by
		moveq		#$00,d2
		move.l		(rp_cp_x,a1),d0			;d0- ax:ay
		jsr		(_LVOGetBlitter,a6)
		jsr		(_LVOVectorRastPort,a6)
		jsr		(_LVOFreeBlitter,a6)
		move.l		(sp)+,d2
NewDrx:	
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		fix02

		move.l		(fbl_GraphicsBase,a6),a6
		jsr		(_LVOUnlockLayerRom,a6)		
fix02:		
		movem.l		(sp)+,d0/d1/a0/a5/a6
		movem.w		d0-d1,(rp_cp_x,a1)			;update x,y			
		rts
		
		
	;
	;do old draw
	;
	
OldDr0:
		movem.l		(sp)+,d0/d1/a0/a5/a6
		movem.l		a1/a5,-(sp)
		move.l		(l_OldDraw,pc),a5
		jsr		(a5)
		move.l		(sp)+,a1
		move.l		(rp_Layer,a1),a5
		tst.l		a5
		beq.s		ODx
		
		jsr		(_LVOUnlockLayerRom,a6)
ODx:
		move.l		(sp)+,a5		
		rts




