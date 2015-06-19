


*-----------------------------------------------------------------------------
*
*	QBSBlitPatch.s V0.23 28.05.2001
*
*	QBSBlit patch, allowing bobs outside chip RAM.
*
*-----------------------------------------------------------------------------
*
* Input:		a1=*bltnode
*
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------



	machine mc68030

	include "lvo/exec_lib.i"
	include	"lvo/graphics_lib.i"
	
	include "exec/memory.i"
	
	include	"hardware/custom.i"
	include	"hardware/blit.i"

	include fblit_library/fblit_lib.i
	include fblit_library/fblitbase.i
	
	include	fblit_library/blitem/be_custom.i

	cnop	0,4

Entry:		bra.s		main

w_FField	dc.w	0					;non-Chip range
l_OldQBSBlit	dc.l	0					;*QBSBlit
l_Func		dc.l	0					;counters
l_ProcCnt	dc.l	0
l_PassCnt	dc.l	0
l_BlitEm	dc.l	0					;BlitEm
l_Debug 	dc.l	0					;debug output
l_user2 	dc.l	0
l_Flags 	dc.l	0					;control flags
l_user3		dc.l	0
l_FBlitBase	dc.l	0					;fblitbase

qbid		dc.l	$10290016

ACTIVE			equ	1				;patch activation
SYNC			equ	2				;beam sync
BLITEMU			equ	3				;use blitter emulator

CUSTOM			equ	$dff000



	;
	;main
	;

main:		
		btst		#ACTIVE,(l_Flags+3,pc)
		bne.s		qbs1				;--> active
qbx1:
		move.l		(l_OldQBSBlit,pc),-(sp)
		rts
qbs1:
		move.l		(bn_function,a1),d0
		move.l		(d0.l),d0
		cmp.l		(qbid,pc),d0
		bne.s		qbx1				;--> wrong call
	
	;that test seems to try and identify a specific piece of bltnode code. Probably
	;it is trying to limit this patch to operating on the GELS code only.

		btst		#SYNC,(l_Flags+3,pc)
		beq.s		qbfast				;--> no synchro, so we do it all in-line
								;    (and no blitter assistance..)
		move.l		($4e,a1),d0
		or.l		($2e,a1),d0
		or.l		($2a,a1),d0
		move.w		(w_FField,pc),d1
		bftst		d0{0:d1}
		beq.s		qbx1				;--> all chip data, and sync, use blitter
		
	;note, since we're here..	$16 - #planes(.b!)
	;				($18 - first word mask)
	;				$1c - bltcon0 (bits 12-15 = A chan shift)
	;				$20 - bltcon1 (bits 12-15 = B chan shift, bit 1 = asc/desc mode)
	;				$22 - modulo for mask and source
	;				$24 - mod for destination
	;				$28 - plane mask
	;				$2a - probably holds the mask data pointer (one plane) (A)
	;				$2e.. is source data (x planes worth) (B)
	;				$4e.. is dest data (x planes) (C, D)
	;				$7e - rows (&$7fff)
	;				$80 - wordwidth (&$7ff)

	
	;
	;This bit runs the bltnode as 'normal', on beam sync interrupts.
	;
	
qbxfast:	
		move.l		a0,-(sp)
		lea		(l_Func,pc),a0
		move.l		(bn_function,a1),(a0)		;store old function
		
	;hmm, that looks like a bad idea. More than one bltnode will be needed at a time,
	;and there is only one function pointer!? Since it works at all I suppose all GELS
	;stuff must be using the same (ROM) bltnode code. Well, the test above somewhere
	;also suggests this.		
		
		lea		(myfunc,pc),a0
		move.l		a0,(bn_function,a1)		;use my function		
		move.l		(sp)+,a0
		bra.s		qbx1		
		
	;
	;fake QBSBlit() bltnode with blitem
	;
myfunc:
		movem.l		a1/a2/a6,-(sp)
		move.l		(l_Func,pc),a2
		move.l		(l_FBlitBase,pc),a0
		move.l		(fbl_BECustom,a0),a0	
		move.w		#$ffff,($4,a0)
		jsr		(a2)				;call old function
		beq.s		myfuncxeq			;--> return 'eq'
		
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOBlitEmFat,a6)
		movem.l		(sp)+,a1/a2/a6
		moveq		#-1,d0
		rts
myfuncxeq:
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOBlitEmFat,a6)
		movem.l		(sp)+,a1/a2/a6
		move.l		(l_Func,pc),d0
		move.l		d0,(bn_function,a1)
		moveq		#00,d0
		rts
	
	
	;		
	;This runs the bltnode in-line, from the QBSBlit() function.
	;
	
qbfast:
		movem.l		a1/a2,-(sp)
		jsr		(_LVOOwnBlitter,a6)		
qbblit1:
		jsr		(_LVOWaitBlit,a6)
		move.l		(l_FBlitBase,pc),a0
		move.l		(fbl_BECustom,a0),a0	
		move.w		#$ffff,($4,a0)
		move.l		(sp),a1
		move.l		(bn_function,a1),a2
		jsr		(a2)
		beq.s		qbblits1				;--> all done
		
		move.l		a6,-(sp)
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOBlitEmFat,a6)
		move.l		(sp)+,a6		
		bra.s		qbblit1
qbblits1:
		move.l		a6,-(sp)
		move.l		(l_FBlitBase,pc),a6
		jsr		(_LVOBlitEmFat,a6)
		move.l		(sp)+,a6		
fqx0:		
		cmp.b		#$40,(bn_stat,a1)
		bne.s		fqx					;--> no cleanup, exit
		
		jsr		(_LVOWaitBlit,a6)
		move.l		#CUSTOM,a0
		move.l		(sp),a1
		move.l		(bn_cleanup,a1),a2
		jsr		(a2)
fqx:
		jsr		(_LVODisownBlitter,a6)
		movem.l		(sp)+,a1/a2
		rts

