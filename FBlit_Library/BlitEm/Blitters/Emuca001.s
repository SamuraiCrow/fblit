

*-----------------------------------------------------------------------------
*
*	Emuca.s V0.01 01.08.98
*
*	© Stephen Brookes 1997-98
*
*	$ca 32bit emulation (D = AB + !AC)
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




emuca:			
		btst		#BBC1_DESC,d0
		beq.s		emu0caxx
		
		lea		(MintTrack,pc),a5
		addq.b		#$01,($cb,a5)
		bra		emu0cabadexit
		
emu0caxx:	tst.w		(w_AShift,a0)
		bne		emu0cabadexit			;--> wrong shift
		
		cmp.w		#$ffff,(bec_bltadat,a0)
		bne		emu0cabadexit			;--> wrong data
		
		btst		#BBC0_AENA,d6
		bne		emu0cabadexit
		
		btst		#BBC0_BENA,d6
		beq		emu0cabadexit

		lea		(MintTrack,pc),a5
		subq.b		#$01,($ca,a5)
		
emu0cabs1:	move.l		(l_Width,a0),d6			;d6- word width
		move.l		(l_Rows,a0),d7			;d7- rows
		move.l		(w_AFWM,a0),d5			;d5- fwm:lwm
		move.w		(w_DRmod,a0),a5			;a5- D row mod
		move.w		(w_BRmod,a0),d4
		ext.l		d4				;d4- B row mod		
		move.l		(w_BShift,a0),d1		;d1- BShift:AShift
	
		moveq		#$01,d3
		swap		d1
	
	
	
	;
	;ascend, copy single word loop (no mask)
	;
		
		cmp.l		d3,d6
		bne.s		emu0cas0			;--> >1.w 
		
		addq.l		#$02,a5				;a5- + modulo
		addq.l		#$02,d4				;d4- + modulo

		move.l		d5,d6
		moveq		#$00,d0
		not.w		d5				;d5- xxxx:!(fwm&lwm)
		
	;1.w copy loop		
		
		lsr.l		#$01,d7
		bcc.s		emu0cal01
		
emu0cal0:	move.w		d5,d2
		move.w		(a2),d0				;d0- ow:nw
		and.w		(a4),d2				;d2- !AC
		move.w		d0,d3				;d3- xx:nw
		lsr.l		d1,d0				;shift
		add.l		d4,a2
		and.w		d6,d0				;d0- AB
		swap		d3				;d3- nw:xx
		or.w		d0,d2				;d2- AB + !AC
		move.w		d2,(a4)				;D = AB + !AC
		move.l		d3,d0				;d0- ow:xx
		add.l		a5,a4
		
emu0cal01:	move.w		d5,d2
		move.w		(a2),d0
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
		dbra		d7,emu0cal0
		
		rts
		
		
	;
	;two word loop
	;		
			
emu0cas0:	cmp.l		#$02,d6
		bne.s		emu0cas1			;--> >1.lw
		
		addq.l		#$04,a5				;a5- + modulo
		addq.l		#$04,d4
		
		moveq		#$00,d0
		not.l		d5
		
	;2.w copy loop
			
		lsr.l		#$01,d7
		bcc.s		emu0cal11

						
emu0cal1:	move.l		d5,d2
		move.l		(a2),d3				;d3- fw:lw
		and.l		(a4),d2				;d2- !AC
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

emu0cal11:	move.l		d5,d2
		move.l		(a2),d3
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
		dbra		d7,emu0cal1
		
		rts
					
		
	;
	;multiple word loop
	;		
		
emu0cas1:	btst		#$00,d6
		bne.s		emu0caoww			;--> odd word width

		move.l		a5,d2
		btst		#$01,d2
		bne		emu0cabadexit			;--> odd word data width
				
		move.l		d5,d3				;d3- fwm:lwm	(d3-flwm)
		move.l		a4,d2		
		move.w		#$ffff,d3			;d3- fwm:ffff
		swap		d5
		move.w		d3,d5
		moveq		#$00,d0
		swap		d5				;d5- ffff:lwm
		btst		#$01,d2
		beq.s		emu0cas11			;--> start lw aligned				

		sub.w		d3,d3
		swap		d5
		subq.l		#$02,a4				;lw align dest
		swap		d3				;d3- 0000:fwm
		subq.l		#$02,a2
		sub.w		d5,d5				;d5- lwm:0000
		addq.l		#$02,d6				;width + 1lw
		subq.l		#$04,a5				;correct modulo
		subq.l		#$04,d4
		bra.s		emu0cas11
		
emu0caoww:	move.l		a5,d2
		btst		#$01,d2
		beq		emu0cabadexit			;--> odd word data width
	
		addq.l		#$01,d6				;width even lw's
		subq.l		#$02,a5				;correct modulo
		subq.l		#$02,d4
		
		move.l		d5,d3				;d3- fwm:lwm 	(d3-flwm)
		move.l		a4,d2
		move.w		#$ffff,d3			;d3- fwm:ffff
		swap		d5				;d5- lwm:fwm 	(d5-llwm)
		moveq		#$00,d0				;d0- 0		(d0-init offset)
		sub.w		d5,d5				;d5- lwm:0000
		btst		#$01,d2
		beq.s		emu0cas11			;--> start lw aligned
		
		move.w		d3,d5				;d5- lwm:ffff
		subq.l		#$02,a2
		swap		d5				;d5- ffff:lwm
		sub.w		d3,d3
		subq.l		#$02,a4				;lw align dest
		swap		d3				;d3- 0000:fwm

emu0cas11:	;add.l		d6,d6
		;add.l		d6,a5				;a5- bpr
		;add.l		d6,d4

		lsr.l		#$01,d6				;d6- lw's
		subq.l		#$03,d6				;d6- # body lw's
	
	
	
		
	;do it (finally!)
		
emu0camwl:	movem.l		d0/a1/a3/a6,-(sp)		;save stuff
;		add.l		d0,a4				;add lw align offset
;		add.l		d0,a2
;		move.l		a4,a3				;a3- D base
;		move.l		a2,a6				;a6- B base

		move.l		d4,a1				;a1- B mod
		move.l		d3,a3				;a3- flwm
		move.l		d5,a6				;a6- llwm
		
		addq.l		#$04,a1
		addq.l		#$04,a5
	
	;copy
		
		not.l		d3
		not.l		d5
		moveq		#$00,d0
		
		tst.l		d6				;d2- # body lw's
		bpl.s		emu0caxs1l2			;--> there is a body
		
;		subq.l		#$04,a5
;		subq.l		#$04,a1
	
emucas1l10:	move.l		d3,d2
		move.l		(a2)+,d4
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
		dbra		d7,emucas1l10
		
		movem.l		(sp)+,d0/a1/a3/a6		
		sub.l		d0,a2
		sub.l		d0,a4
		rts
	
	
	

emu0caxs1l2:	move.l		a3,d2
		move.l		(a2)+,d4			;d4- fw:lw
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
		
emu0caxs1l20:	move.l		(a2)+,d4			;d4- fw:lw
		move.l		d4,d2				;d2- fw:lw
		move.w		d4,d0				;d0- olw:lw
		lsr.l		d1,d4				;d4- xx:nlw
		swap		d0				;d0- lw:olw
		move.w		d0,d2				;d2- fw:olw
		ror.l		d1,d2				;d2- nfw:xx
		move.w		d4,d2
		move.l		d2,(a4)+
		dbra		d6,emu0caxs1l20
		
		swap		d6
		
		move.l		a6,d2
		move.l		(a2),d4
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
		dbra		d7,emu0caxs1l2
		
emu0casx5:	movem.l		(sp)+,d0/a1/a3/a6
		sub.l		d0,a2
		sub.l		d0,a4
		rts
		
	


	
	;
	;descend, clear/fill single word loop
	;
		
emu0cadescend:	exg.l		a5,d2
		lea		(MintTrack,pc),a5
		addq.b		#$01,($0b,a5)
		exg.l		a5,d2
		
		cmp.l		#$01,d6
		bne.s		demu0cas0			;--> >1.w 
		
		addq.l		#$02,a5				;a5- + modulo
		addq.l		#$02,d4				;d4- + modulo
		
		move.l		a5,d2
		neg.l		d2
		neg.l		d4
		move.l		d2,a5
		
;		bra		emu0ca1wl
		
		
	;
	;two word loop
	;		
			
demu0cas0:	cmp.l		#$02,d6
		bne.s		demu0cas1			;--> >1.lw
		
		addq.l		#$04,a5				;a5- + modulo
		addq.l		#$04,d4
		
		subq.l		#$02,a1				;modify pntrs
		subq.l		#$02,a4
		
		move.l		a5,d2
		neg.l		d2
		neg.l		d4
		move.l		d2,a5
		
;		bsr		emu0ca2wl
		
		addq.l		#$02,a1
		addq.l		#$02,a4
		
		rts
						
		
	;
	;multiple word loop
	;		
		
demu0cas1:	btst		#$00,d6
		bne.s		demu0caoww			;--> odd word width

		move.l		a5,d2
		btst		#$01,d2
		bne		emu0cabadexit			;--> odd word data width
				
		move.l		a4,d2
		moveq		#-2,d0
		move.l		d5,d3				;d3- fwm:lwm
		move.w		#$ffff,d3
		swap		d5
		move.w		d3,d5				;d5- lwm:ffff
		swap		d3				;d3- ffff:fwm
		
		btst		#$01,d2
		bne.s		demu0cas11			;--> start lw aligned				

		swap		d3
		moveq		#$00,d0
		sub.w		d3,d3				;d3- fwm:0000
		sub.w		d5,d5
		swap		d5				;d5- 0000:lwm
		addq.l		#$02,d6				;width + 1lw
		subq.l		#$04,a5				;correct modulo
		subq.l		#$04,d4
		bra.s		demu0cas11
		
demu0caoww:	move.l		a5,d2
		btst		#$01,d2
		beq.s		emu0cabadexit			;--> odd word data width
	
		addq.l		#$01,d6				;width even lw's
		subq.l		#$02,a5				;correct modulo
		subq.l		#$02,d4
		
		move.l		d5,d3				;d3- fwm:lwm
		move.l		a4,d2
		move.w		#$ffff,d3
		moveq		#-2,d0
		and.l		#$ffff,d5			;d5- 0000:lwm
		swap		d3				;d3- ffff:fwm
		btst		#$01,d2
		bne.s		demu0cas11			;--> start lw aligned
		
		swap		d3
		swap		d5
		move.w		d3,d5				;d5- lwm:ffff
		clr.w		d3				;d3- fwm:0000
		moveq		#$00,d0

demu0cas11:	add.l		d6,d6
		add.l		d6,a5				;a5- bpr
		add.l		d6,d4

		neg.l		d4
		move.l		a5,d2
		neg.l		d2
		move.l		d2,a5
		
		lsr.l		#$02,d6				;d6- lw's
		subq.l		#$03,d6				;d6- # body lw's
		bpl		emu0camwl
		
		exg.l		d3,d5
		subq.l		#$04,a1
		subq.l		#$04,a4
		bsr		emu0camwl
		addq.l		#$04,a1
		addq.l		#$04,a4
		rts
	
		
emu0cagoodexit:	rts		

emu0cabadexit:	bra		emu16

emucagoodexit:	rts
