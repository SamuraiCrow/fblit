

*-----------------------------------------------------------------------------
*
*	Emuxa.s V0.01 01.08.98
*
*	© Stephen Brookes 1997-98
*
*	$xa 32bit limited emulation
*
*-----------------------------------------------------------------------------
*
* Input:		a0=*be_custom
*			a1=A
*			a2=B
*			a3=C
*			a4=D
*
* Output:		-
*
* Trashed:		-
*
*-----------------------------------------------------------------------------




emuxa:		move.w		(bec_bltcon0,a0),d6
		move.w		(bec_bltcon1,a0),d0
		moveq		#$f,d1
		and.b		d6,d1
		cmp.b		#$0a,d1
		bne.s		emuxabadexit			;--> not an xa blit...
	bra.s		emuxabadexit	
		btst		#BBC0_CENA,d6
		beq.s		emuxabadexit			;--> no channel C		
		
		cmp.l		a3,a4
		bne.s		emuxabadexit			;--> channel D != C
		
		move.w		(w_DRmod,a0),d1
		cmp.w		(w_CRmod,a0),d1
		bne.s		emuxabadexit			;--> channel D != C
		
		lsr.b		#$04,d6
		beq.s		emu0fa				;--> $0a blit
		
		cmp.b		#$0f,d6
		beq.s		emu0fa				;--> $0f blit		
		
		cmp.b		#$0c,d6
		beq		emuca				;--> $ca blit
		
		cmp.b		#$03,d6
		beq		emu3a
		
emuxagoodexit:	;rts
		
emuxabadexit:	bra		emu16	



	include "blitem/blitters/emu0fa0027.s"
	include	"blitem/blitters/emuca001.s"
	include "blitem/blitters/emu3a001.s"
		


