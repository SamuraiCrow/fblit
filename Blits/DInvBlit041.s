

*-----------------------------------------------------------------------------
*
*	DInvBlit.s V0.41 26.06.98
*
*	© Stephen Brookes 1997-98
*
*	Invert a region.
*
*-----------------------------------------------------------------------------
*
*
*	Input:		a1		- dest plane (at first lw)
*
*			l_DstBmpDelta	- inter row delta
*			l_DstStart	- dest start bit
*			l_BTH2		- body:tail/head (non-combined!)
*			w_Rows		- #rows
*
*	Trashed:	d0-d5/a0/a1/a5
*
*-----------------------------------------------------------------------------



DInvBlit:	move.l		(l_DstBmpDelta,a6),d1
		move.w		(w_Rows,a6),d2
		move.l		(l_BTH2,a6),d3



DIHead: 	tst.b		d3				;any head?
		beq.s		DIBody

		move.l		(l_DstStart,a6),d4
		moveq		#0,d0
		bfset		d0{d4:d3}			;head mask
		bsr.s		DInvNA
		addq.l		#$04,a1				;next lw

DIBody: 	swap		d3				;any body?
		tst.w		d3
		beq.s		DITail

		move.l		d2,d5				;set #rows
		lea		(a1,d3.w*4),a0			;figure out next addr
		subq.w		#$01,d3
		move.l		a1,a5				;save base row addr

DIBodyl1:	move.w		d3,d4				;reset lw count
		lsr.w		#$01,d4
		bcc.s		DIBodyl2s0

DIBodyl2:	not.l		(a1)+
DIBodyl2s0:	not.l		(a1)+
		dbra		d4,DIBodyl2

		add.l		d1,a5				;start of next row
		move.l		a5,a1
		dbra		d5,DIBodyl1

		move.l		a0,a1				;restore next dst addr


DITail: 	rol.l		#$08,d3 			;any tail?
		tst.b		d3
		beq.s		DInvBlitX
		moveq		#0,d0
		bfset		d0{0:d3}			;tail mask
		;**** returns through DInvNA, not DInvBlitX!! ****
		

DInvNA: 	move.l		d2,d5				;d5=#rows
		move.l		a1,a0				;a0=addr
		move.l		d1,d4
		move.l		a1,a5
		add.l		d4,d4				;d4=2row bmpdelta
		add.l		d1,a5				;a5=addr+1row

		lsr.w		#$01,d5
		bcc.s		DINAl01

DINAl0: 	eor.l		d0,(a5)  
		add.l		d4,a5
DINAl01:	eor.l		d0,(a0)
		add.l		d4,a0
		dbra		d5,DINAl0 
DInvBlitX:	rts			  
