

*-----------------------------------------------------------------------------
*
*	Emu3a.s V0.01 01.08.98
*
*	© Stephen Brookes 1997-98
*
*	$3a 32bit emulation (D = AB + !AC)
*
*-----------------------------------------------------------------------------
*
* Input:		d6=bltcon0 (invalid minterm)
*			a0=*be_custom
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




emu3a:
		btst		#BBC1_DESC,d0
		beq.s		emu03axx

		lea		(MintTrack,pc),a5
		addq.b		#$01,($3b,a5)
		bra		emu03abadexit

emu03axx:	tst.w		(w_AShift,a0)
		bne		emu03abadexit			;--> wrong shift

		cmp.w		#$ffff,(bec_bltadat,a0)
		bne		emu03abadexit			;--> wrong data

		btst		#BBC0_AENA,d6
		bne		emu03abadexit

		btst		#BBC0_BENA,d6
		beq		emu03abadexit

		lea		(MintTrack,pc),a5
		subq.b		#$01,($3a,a5)

emu03abs1:	move.l		(l_Width,a0),d6 		;d6- word width
		move.l		(l_Rows,a0),d7			;d7- rows
		move.l		(w_AFWM,a0),d5			;d5- fwm:lwm
		move.w		(w_DRmod,a0),a5 		;a5- D row mod
		move.w		(w_BRmod,a0),d4
		ext.l		d4				;d4- B row mod
		move.l		(w_BShift,a0),d1		;d1- BShift:AShift

		moveq		#$01,d3
		swap		d1



	;
	;ascend, copy single word loop (no mask)
	;›
	
		cmp.l		d3,d6
		bne.s		emu03as0			;--> >1.w

		addq.l		#$02,a5 			;a5- + modulo
		addq.l		#$02,d4 			;d4- + modulo

		move.l		d5,d6
		moveq		#-1,d0
		not.w		d5				;d5- xxxx:!(fwm&lwm)

	;1.w copy loop

		lsr.l		#$01,d7
		bcc.s		emu03al01

emu03al0:	move.w		d5,d2
		move.w		(a2),d0 			;d0- ow:nw
		not.w		d0	 ; invt src
		and.w		(a4),d2 			;d2- !AC
		move.w		d0,d3				;d3- xx:nw
		lsr.l		d1,d0				;shift
		add.l		d4,a2
		and.w		d6,d0				;d0- AB
		swap		d3				;d3- nw:xx
		or.w		d0,d2				;d2- AB + !AC
		move.w		d2,(a4) 			;D = AB + !AC
		move.l		d3,d0				;d0- ow:xx
		add.l		a5,a4

emu03al01:	move.w		d5,d2
		move.w		(a2),d0
		not.w		d0	; invt src
		and.w		(a4),d2
		move.w		d0,d3
		lsr.l		d1,d0
		add.l		d4,a2
		and.w		d6,d0
		swap		d3
		or.w		d0,d2
		move.w		d2,(a4)
		move.l		d3,d0
		add.l		a5,a4
		dbra		d7,emu03al0

		rts


	;
	;two word loop
	;

emu03as0:	cmp.l		#$02,d6
		bne.s		emu03as1			;--> >1.lw

		addq.l		#$04,a5 			;a5- + modulo
		addq.l		#$04,d4

		moveq		#-1,d0
		not.l		d5

	;2.w copy loop

		lsr.l		#$01,d7
		bcc.s		emu03al11


emu03al1:	move.l		d5,d2
		move.l		(a2),d3 			;d3- fw:lw
		not.l		d3	 ;invt src
		and.l		(a4),d2 			;d2- !AC
		not.l		d5
		move.l		d3,d6				;d6- fw:lw
		move.w		d3,d0				;d0- olw:lw
		lsr.l		d1,d3				;d3- xx:nlw
		swap		d0				;d0- lw:olw
		move.w		d0,d6				;d6- fw:olw
		ror.l		d1,d6				;d6- nfw:xx
		add.l		d4,a2
		move.w		d3,d6				;d6- nfw:nlw
		and.l		d5,d6
		or.l		d6,d2
		move.l		d2,(a4)
		not.l		d5
		add.l		a5,a4

emu03al11:	move.l		d5,d2
		move.l		(a2),d3
		not.l		d3	 ;invt src
		and.l		(a4),d2
		not.l		d5
		move.l		d3,d6
		move.w		d3,d0
		lsr.l		d1,d3
		swap		d0
		move.w		d0,d6
		ror.l		d1,d6
		add.l		d4,a2
		move.w		d3,d6
		and.l		d5,d6
		or.l		d6,d2
		move.l		d2,(a4)
		not.l		d5
		add.l		a5,a4
		dbra		d7,emu03al1

		rts


	;
	;multiple word loop
	;

emu03as1:	btst		#$00,d6
		bne.s		emu03aoww			;--> odd word width

		move.l		a5,d2
		btst		#$01,d2
		bne		emu03abadexit			;--> odd word data width

		move.l		d5,d3				;d3- fwm:lwm	(d3-flwm)
		move.l		a4,d2
		move.w		#$ffff,d3			;d3- fwm:ffff
		swap		d5
		move.w		d3,d5
		moveq		#$00,d0
		swap		d5				;d5- ffff:lwm
		btst		#$01,d2
		beq.s		emu03as11			;--> start lw aligned

		sub.w		d3,d3
		swap		d5
		subq.l		#$02,a4 			;lw align dest
		swap		d3				;d3- 0000:fwm
		subq.l		#$02,a2
		sub.w		d5,d5				;d5- lwm:0000
		addq.l		#$02,d6 			;width + 1lw
		subq.l		#$04,a5 			;correct modulo
		subq.l		#$04,d4
		bra.s		emu03as11

emu03aoww:	move.l		a5,d2
		btst		#$01,d2
		beq		emu03abadexit			;--> odd word data width

		addq.l		#$01,d6 			;width even lw's
		subq.l		#$02,a5 			;correct modulo
		subq.l		#$02,d4

		move.l		d5,d3				;d3- fwm:lwm	(d3-flwm)
		move.l		a4,d2
		move.w		#$ffff,d3			;d3- fwm:ffff
		swap		d5				;d5- lwm:fwm	(d5-llwm)
		moveq		#$00,d0 			;d0- 0		(d0-init offset)
		sub.w		d5,d5				;d5- lwm:0000
		btst		#$01,d2
		beq.s		emu03as11			;--> start lw aligned

		move.w		d3,d5				;d5- lwm:ffff
		subq.l		#$02,a2
		swap		d5				;d5- ffff:lwm
		sub.w		d3,d3
		subq.l		#$02,a4 			;lw align dest
		swap		d3				;d3- 0000:fwm

emu03as11:	lsr.l		#$01,d6 			;d6- lw's
		subq.l		#$03,d6 			;d6- # body lw's




	;do it (finally!)

emu03amwl:	movem.l 	d0/a1/a3/a6,-(sp)		;save stuff

		move.l		d4,a1				;a1- B mod
		move.l		d3,a3				;a3- flwm
		move.l		d5,a6				;a6- llwm

		addq.l		#$04,a1
		addq.l		#$04,a5

	;copy

		not.l		d3
		not.l		d5
		moveq		#-1,d0

		tst.l		d6				;d2- # body lw's
		bpl.s		emu03axs1l2			;--> there is a body

emu3as1l10:	move.l		d3,d2
		move.l		(a2)+,d4
		not.l		d4	 ; invt src
		and.l		(a4),d2
		move.l		d4,d6				;d6- fw:lw
		swap		d4				;d4- lw:fw
		lsr.l		d1,d6				;d6- xx:nlw
		move.w		d4,d0				;d0- olw:fw
		not.l		d3
		lsr.l		d1,d0				;d0- xx:nfw
		swap		d0				;d0- nfw:xx
		move.w		d6,d0				;d0- nfw:nlw
		exg		d4,d0				;d0- olw:xx, d4- nfw:nlw
		and.l		d3,d4
		or.l		d4,d2
		move.l		d2,(a4)+
		not.l		d3

		move.l		d5,d2
		move.l		(a2),d4
		not.l		d4	 ;invt src
		and.l		(a4),d2
		move.l		d4,d6
		swap		d4
		lsr.l		d1,d6
		move.w		d4,d0
		not.l		d5
		lsr.l		d1,d0
		swap		d0
		move.w		d6,d0
		exg		d4,d0
		and.l		d5,d4
		add.l		a1,a2
		or.l		d4,d2
		move.l		d2,(a4)
		not.l		d5
		add.l		a5,a4
		dbra		d7,emu3as1l10

		movem.l 	(sp)+,d0/a1/a3/a6
		sub.l		d0,a2
		sub.l		d0,a4
		rts




emu03axs1l2:	move.l		a3,d2
		move.l		(a2)+,d4			;d4- fw:lw
		not.l		d4	;invt src
		not.l		d2
		move.l		a3,d3
		and.l		(a4),d2
		move.l		d4,d5				;d5- fw:lw
		move.w		d4,d0				;d0- olw:lw
		lsr.l		d1,d4				;d4- xx:nlw
		swap		d0				;d0- lw:olw
		move.w		d0,d5				;d5- fw:olw
		ror.l		d1,d5				;d5- nfw:xx
		move.w		d4,d5				;d5- nfw:nlw
		and.l		d3,d5
		or.l		d5,d2
		move.l		d2,(a4)+

		move.w		d6,d4
		swap		d6
		move.w		d4,d6

emu03axs1l20:	move.l		(a2)+,d4			;d4- fw:lw
		not.l		d4	;invt src
		move.l		d4,d2				;d2- fw:lw
		move.w		d4,d0				;d0- olw:lw
		lsr.l		d1,d4				;d4- xx:nlw
		swap		d0				;d0- lw:olw
		move.w		d0,d2				;d2- fw:olw
		ror.l		d1,d2				;d2- nfw:xx
		move.w		d4,d2
		move.l		d2,(a4)+
		dbra		d6,emu03axs1l20

		swap		d6

		move.l		a6,d2
		move.l		(a2),d4
		not.l		d4	; invt src
		not.l		d2
		move.l		a6,d3
		and.l		(a4),d2
		move.l		d4,d5
		move.w		d4,d0
		lsr.l		d1,d4
		swap		d0
		move.w		d0,d5
		ror.l		d1,d5
		move.w		d4,d5
		and.l		d3,d5
		or.l		d5,d2
		move.l		d2,(a4)

		add.l		a1,a2
		add.l		a5,a4
		dbra		d7,emu03axs1l2

emu03asx5:	movem.l 	(sp)+,d0/a1/a3/a6
		sub.l		d0,a2
		sub.l		d0,a4
		rts


emu03agoodexit: rts

emu03abadexit:	bra.s		emu16

emu3agoodexit:	rts
