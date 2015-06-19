

*-----------------------------------------------------------------------------
*
*	FillBlit.s V0.423 26.06.98
*
*	© Stephen Brookes 1997-98
*
*	Fill a region.
*
*-----------------------------------------------------------------------------
*
*
*	Input:		d0.b		- type, null clear, else fill
*			a1		- dest plane (at first lw)
*
*			l_DstBmpDelta	- inter row delta
*			l_DstStart	- dest start bit
*			l_BTH2		- body:tail/head (non-combined!)
*			w_Rows		- #rows
*
*	Trashed:	d0-d5/a0/a1/a5
*
*-----------------------------------------------------------------------------



FillBlit:	move.l		d6,-(sp)
		extb.l		d0 				;fill or clear...
		beq.s		FlBlits1
		moveq		#-1,d0

FlBlits1:	move.l		(l_DstBmpDelta,a6),d1
		move.w		(w_Rows,a6),d2
		move.l		(l_BTH2,a6),d3



FlHead: 	tst.b		d3				;any head?
		beq.s		FlBody

		move.l		(l_DstStart,a6),d4
		moveq		#0,d6
		bfset		d6{d4:d3}			;head mask
		bsr.s		FillNA
		addq.l		#$04,a1 			;next lw

FlBody: 	swap		d3				;any body?
		tst.w		d3
		beq.s		FlTail

		move.l		d2,d5				;set #rows
		lea		(a1,d3.w*4),a0			;figure out next addr
		subq.w		#$01,d3
		move.l		a1,a5				;save base row addr

FlBodyl1:	move.w		d3,d4				;reset lw count
		lsr.w		#$01,d4
		bcc.s		FlBodyl2s0

FlBodyl2:	move.l		d0,(a1)+
FlBodyl2s0:	move.l		d0,(a1)+
		dbra		d4,FlBodyl2

		add.l		d1,a5				;start of next row
		move.l		a5,a1
		dbra		d5,FlBodyl1

		move.l		a0,a1				;restore next dst addr


FlTail: 	rol.l		#$08,d3 			;any tail?
		tst.b		d3
		beq.s		FillBlitX
		clr.l		d6
		bfset		d6{0:d3}			;tail mask
		bsr.s		FillNA


FillBlitX:	move.l		(sp)+,d6
		rts


FillNA: 	move.l		d2,d5				;d5=#rows
		move.l		a1,a0				;a0=addr
		move.l		d1,d4
		move.l		a1,a5
		add.l		d4,d4				;d4=2row bmpdelta
		add.l		d1,a5				;a5=addr+1row
		tst.b		d0				;fill | clear?
		bne.s		FlNAl1s0			;fill...

		not.l		d6				;invert mask
		lsr.w		#$01,d5
		bcc.s		FlNAl01

FlNAl0: 	and.l		d6,(a5) 
		add.l		d4,a5
FlNAl01:	and.l		d6,(a0)
		add.l		d4,a0
		dbra		d5,FlNAl0
		rts			 

FlNAl1s0:	lsr.w		#$01,d5
		bcc.s		FlNAl11

FlNAl1: 	or.l		d6,(a5)
		add.l		d4,a5
FlNAl11:	or.l		d6,(a0)
		add.l		d4,a0
		dbra		d5,FlNAl1
		rts

