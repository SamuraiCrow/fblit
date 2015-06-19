

*-----------------------------------------------------------------------------
*
*	Emu0fa.s V0.027 08.08.98
*
*	© Stephen Brookes 1997-98
*
*	$0a/fa 32bit emulation (D = !AC, D = A+C)
*
*-----------------------------------------------------------------------------
*
* Input:		d0=bltcon1
*			d6=bltcon0 (invalid minterm)
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




emu0fa:		btst		#BBC1_DESC,d0
		bne		emu0fadescend
		
		moveq		#$00,d1
		tst.w		(w_AShift,a0)
		beq.s		emu0faxx
		
		lea		(MintTrack,pc),a5
		addq.b		#$01,($00,a5)
		moveq		#$01,d1
		
emu0faxx:	cmp.w		#$ffff,(bec_bltadat,a0)
		beq.s		emu0faxxx
		
		lea		(MintTrack,pc),a5
		addq.b		#$01,($01,a5)
		moveq		#$01,d1
				
emu0faxxx:	tst.l		d1
		beq.s		emu0faxxxxx		
		
		lea		(MintTrack,pc),a5
		cmp.b		#$0f,d6
		beq.s		emu0faxxxx
		
		subq.b		#$01,($0a,a5)
		bra		emu0fabadexit
		
emu0faxxxx:	subq.b		#$01,($fa,a5)
		bra		emu0fabadexit		
		
emu0faxxxxx:	lea		(MintTrack,pc),a5
		move.w		d6,d1				;d1- bltcon0
		tst.b		d1
		beq.s		emu0fabs0
		
		subq.b		#$01,($fa,a5)
		bra.s		emu0fabs1
		
emu0fabs0:	subq.b		#$01,($0a,a5)		

emu0fabs1:	move.l		(l_Width,a0),d6			;d6- word width
		move.l		(l_Rows,a0),d7			;d7- rows
		move.l		(w_AFWM,a0),d5			;d5- fwm:lwm
		move.w		(w_DRmod,a0),a5			;a5- D row mod
		move.w		(w_ARmod,a0),d4
		ext.l		d4				;d4- A row mod		
	
		moveq		#$01,d3
	
	
	
	;
	;ascend, clear/fill single word loop
	;
		
		cmp.l		d3,d6
		bne.s		emu0fas0			;--> >1.w 
		
		addq.l		#$02,a5				;a5- + modulo
		addq.l		#$02,d4				;d4- + modulo
		
emu0fa1wl:	cmp.b		#$0f,d1
		beq.s		emu0fawfl			;--> fill mode
		
		btst		#BBC0_AENA,d1
		bne.s		emu0fasx0			;--> A channel on
		
		not.w		d5
		
	;1.w clear loop		
		
		lsr.l		#$01,d7
		bcc.s		emu0fal01
		
emu0fal0:	and.w		d5,(a4)
		add.l		a5,a4
emu0fal01:	and.w		d5,(a4)
		add.l		a5,a4		
		dbra		d7,emu0fal0
		
		rts
		
	;1.w clear loop (active A)		
		
emu0fasx0:	lsr.l		#$01,d7
		bcc.s		emu0faxl01
		
emu0faxl0:	move.w		d5,d3				
		and.w		(a1),d3
		not.w		d3
		add.l		d4,a1
		and.w		d3,(a4)
		add.l		a5,a4
emu0faxl01:	move.w		d5,d2
		and.w		(a1),d2
		not.w		d2
		add.l		d4,a1
		and.w		d2,(a4)
		add.l		a5,a4
		dbra		d7,emu0faxl0
		
		rts
						
emu0fawfl:	btst		#BBC0_AENA,d1
		bne.s		emu0fawfs0			;--> A channel on
		
	;1.w fill loop
			
		lsr.l		#$01,d7
		bcc.s		emu0fawfl01
		
emu0fawfl0:	or.w		d5,(a4)
		add.l		a5,a4
emu0fawfl01:	or.w		d5,(a4)
		add.l		a5,a4
		dbra		d7,emu0fawfl0
		
		rts				
	
	;1.w fill loop (active A)
	
emu0fawfs0:	lsr.l		#$01,d7
		bcc.s		emu0fawfxl01
		
emu0fawfxl0:	move.l		d5,d3
		and.w		(a1),d3
		or.w		d3,(a4)
		add.l		d4,a1
		add.l		a5,a4
emu0fawfxl01:	move.w		d5,d2
		and.w		(a1),d2
		or.w		d2,(a4)
		add.l		d4,a1
		add.l		a5,a4
		dbra		d7,emu0fawfxl0				
		
		rts
		
		
		
	;
	;two word loop
	;		
			
emu0fas0:	cmp.l		#$02,d6
		bne.s		emu0fas1			;--> >1.lw
		
		addq.l		#$04,a5				;a5- + modulo
		addq.l		#$04,d4

emu0fa2wl:	cmp.b		#$0f,d1
		beq.s		emu0falfl			;--> fill mode
		
		btst		#BBC0_AENA,d1
		bne.s		emu0fasx1			;--> A enabled
		
		not.l		d5
		
	;2.w clear loop
			
		lsr.l		#$01,d7
		bcc.s		emu0fal11
						
emu0fal1:	and.l		d5,(a4)
		add.l		a5,a4
emu0fal11:	and.l		d5,(a4)
		add.l		a5,a4		
		dbra		d7,emu0fal1
		
		rts
		
	;2.w clear loop (active A)
	
emu0fasx1:	lsr.l		#$01,d7
		bcc.s		emu0falx11
		
emu0falx1:	move.l		d5,d3
		and.l		(a1),d3
		not.l		d3
		and.l		d3,(a4)
		add.l		d4,a1
		add.l		a5,a4
emu0falx11:	move.l		d5,d2
		and.l		(a1),d2
		not.l		d2
		and.l		d2,(a4)
		add.l		d4,a1
		add.l		a5,a4
		dbra		d7,emu0falx1
		
		rts
		
emu0falfl:	btst		#BBC0_AENA,d1
		bne.s		emu0faxs2			;--> A active
		
	;2.w fill loop
			
		lsr.l		#$01,d7
		bcc.s		emu0falfl01
		
emu0falfl0:	or.l		d5,(a4)
		add.l		a5,a4
emu0falfl01:	or.l		d5,(a4)
		add.l		a5,a4
		dbra		d7,emu0falfl0
		
		rts						
		
	;2.w fill loop (active A)
	
emu0faxs2:	lsr.l		#$01,d7
		bcc.s		emu0falfl11
		
emu0falfl1:	move.l		d5,d3
		and.l		(a1),d3
		or.l		d3,(a4)
		add.l		d4,a1
		add.l		a5,a4
emu0falfl11:	move.l		d5,d2
		and.l		(a1),d2
		or.l		d2,(a4)
		add.l		d4,a1
		add.l		a5,a4
		dbra		d7,emu0falfl1
		
		rts
		
						
		
	;
	;multiple word loop
	;		
		
emu0fas1:	btst		#$00,d6
		bne.s		emu0faoww			;--> odd word width

		move.l		a5,d2
		btst		#$01,d2
		bne		emu0fabadexit			;--> odd word data width
				
		move.l		d5,d3				;d3- fwm:lwm	(d3-flwm)
		move.l		a4,d2		
		move.w		#$ffff,d3			;d3- fwm:ffff
		swap		d5
		move.w		d3,d5
		moveq		#$00,d0
		swap		d5				;d5- ffff:lwm
		btst		#$01,d2
		beq.s		emu0fas11			;--> start lw aligned				

		sub.w		d3,d3
		swap		d5
		swap		d3				;d3- 0000:fwm
		sub.w		d5,d5				;d5- lwm:0000
		moveq		#-2,d0
		addq.l		#$02,d6				;width + 1lw
		subq.l		#$04,a5				;correct modulo
		subq.l		#$04,d4
		bra.s		emu0fas11
		
emu0faoww:	move.l		a5,d2
		btst		#$01,d2
		beq		emu0fabadexit			;--> odd word data width
	
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
		beq.s		emu0fas11			;--> start lw aligned
		
		move.w		d3,d5				;d5- lwm:ffff
		swap		d5				;d5- ffff:lwm
		sub.w		d3,d3
		swap		d3				;d3- 0000:fwm
		moveq		#-2,d0				;d0- -2

emu0fas11:	add.l		d6,d6
		add.l		d6,a5				;a5- bpr
		add.l		d6,d4

		lsr.l		#$02,d6				;d6- lw's
		subq.l		#$03,d6				;d6- # body lw's
	
	
	
		
	;do it (finally!)
		
emu0famwl:	movem.l		d0/a2/a3,-(sp)			;save stuff
		add.l		d0,a4				;add lw align offset
		add.l		d0,a1
		move.l		a4,a3				;a3- D base
		move.l		a1,a2				;a2- A base
		
		cmp.b		#$0f,d1
		beq		emu0fas1fm			;--> fill mode		

		btst		#BBC0_AENA,d1
		bne.s		emu0faxs3			;--> A active
	
	
	
	;clear
		
		not.l		d3
		not.l		d5
		moveq		#$00,d0
		
		move.l		d6,d2				;d2- # body lw's
		bpl.s		emufas1l2			;--> there is a body
		
		subq.l		#$04,a5
		lsr.l		#$01,d7
		bcc.s		emufas1l11
	
emufas1l10:	and.l		d3,(a4)+
		and.l		d5,(a4)
		add.l		a5,a4		
emufas1l11:	and.l		d3,(a4)+			;first lw
		and.l		d5,(a4)				;last lw
		add.l		a5,a4
		dbra		d7,emufas1l10

		bra.s		emufasx2
		
emufas1l2:	and.l		d3,(a4)+
emufas1l20:	move.l		d0,(a4)+
		dbra		d2,emufas1l20
		
		and.l		d5,(a4)
		
		add.l		a5,a3
		move.l		d6,d2
		move.l		a3,a4
		dbra		d7,emufas1l2

emufasx2:	movem.l		(sp)+,d0/a2/a3		
		sub.l		d0,a1
		sub.l		d0,a4
		rts
	
	
	
	
	;clear active A
		
emu0faxs3:	move.l		d6,d2				;d2- # body lw's
		bpl.s		emu0faxs1l2			;--> there is a body
		
		subq.l		#$04,a5
		subq.l		#$04,d4
		lsr.l		#$01,d7
		bcc.s		emu0faxs1l11
	
emu0faxs1l10:	move.l		d3,d1
		and.l		(a1)+,d1
		move.l		d5,d2
		and.l		(a1),d2
		not.l		d1
		and.l		d1,(a4)+
		not.l		d2
		and.l		d2,(a4)
		add.l		d4,a1
		add.l		a5,a4
emu0faxs1l11:	move.l		d3,d1
		and.l		(a1)+,d1
		move.l		d5,d2
		and.l		(a1),d2
		not.l		d1
		and.l		d1,(a4)+
		not.l		d2
		and.l		d2,(a4)
		add.l		d4,a1
		add.l		a5,a4
		dbra		d7,emu0faxs1l10
		
		bra.s		emu0fasx5
				
emu0faxs1l2:	move.l		d3,d1
		and.l		(a1)+,d1
		not.l		d1
		and.l		d1,(a4)+
		
emu0faxs1l20:	move.l		(a1)+,d0
		not.l		d0
		and.l		d0,(a4)+
		dbra		d2,emu0faxs1l20
		
		move.l		d5,d1
		and.l		(a1),d1
		not.l		d1
		and.l		d1,(a4)
		add.l		d4,a2
		add.l		a5,a3
		move.l		d6,d2
		move.l		a2,a1
		move.l		a3,a4
		dbra		d7,emu0faxs1l2
		
emu0fasx5:	movem.l		(sp)+,d0/a2/a3
		sub.l		d0,a1
		sub.l		d0,a4
		rts
		
	
	
	
	;fill

emu0fas1fm:	btst		#BBC0_AENA,d1
		bne.s		emu0faxs4			;--> active A
	
		moveq		#-1,d4
		move.l		d6,d2				;d2- # body lw's
		bpl.s		emuffas1l2			;--> there is a body
		
		subq.l		#$04,a5
		lsr.l		#$01,d7
		bcc.s		emuffas1l11
	
emuffas1l10:	or.l		d3,(a4)+
		or.l		d5,(a4)
		add.l		a5,a4		
emuffas1l11:	or.l		d3,(a4)+			;first lw
		or.l		d5,(a4)				;last lw
		add.l		a5,a4
		dbra		d7,emuffas1l10
		
		bra.s		emuffasx0
		
emuffas1l2:	or.l		d3,(a4)+
emuffas1l20:	move.l		d4,(a4)+
		dbra		d2,emuffas1l20
		
		or.l		d5,(a4)
		add.l		a5,a3
		move.l		d6,d2
		move.l		a3,a4
		dbra		d7,emuffas1l2
		
emuffasx0:	movem.l		(sp)+,d0/a2/a3
		sub.l		d0,a1
		sub.l		d0,a4
		rts		





	;fill active
	
emu0faxs4:	move.l		d6,d2				;d2- # body lw's
		bpl.s		emuffaxs1l2			;--> there is a body
		
		subq.l		#$04,d4
		subq.l		#$04,a5
		lsr.l		#$01,d7
		bcc.s		emuffaxs1l11
	
emuffaxs1l10:	move.l		d3,d1
		and.l		(a1)+,d1
		move.l		d5,d2
		and.l		(a1),d2
		or.l		d1,(a4)+
		or.l		d2,(a4)
		add.l		d4,a1
		add.l		a5,a4
emuffaxs1l11:	move.l		d3,d1
		and.l		(a1)+,d1
		move.l		d5,d2
		and.l		(a1),d2
		or.l		d1,(a4)+			;first lw
		or.l		d2,(a4)				;last lw
		add.l		d4,a1
		add.l		a5,a4
		dbra		d7,emuffaxs1l10
		
		bra.s		emu0fasx4
				
emuffaxs1l2:	move.l		d3,d0
		and.l		(a1)+,d0
		or.l		d0,(a4)+
		
emuffaxs1l20:	move.l		(a1)+,d0
		or.l		d0,(a4)+
		dbra		d2,emuffaxs1l20
		
		move.l		d5,d0
		and.l		(a1)+,d0
		or.l		d0,(a4)+
		add.l		a4,a2
		add.l		a5,a3
		move.l		d6,d2
		move.l		a2,a1
		move.l		a3,a4
		dbra		d7,emuffaxs1l2
		
emu0fasx4:	movem.l		(sp)+,d0/a2/a3
		sub.l		d0,a1
		sub.l		d0,a4
		rts		






	
	;
	;descend, clear/fill single word loop
	;
		
emu0fadescend:	lea		(MintTrack,pc),a5
		addq.b		#$01,($0b,a5)
		moveq		#$00,d1
		tst.w		(w_AShift,a0)
		beq.s		zemu0faxx
		
		lea		(MintTrack,pc),a5
		addq.b		#$01,($0c,a5)
		moveq		#$01,d1
		
zemu0faxx:	cmp.w		#$ffff,(bec_bltadat,a0)
		beq.s		zemu0faxxx
		
		lea		(MintTrack,pc),a5
		addq.b		#$01,($0d,a5)
		moveq		#$01,d1

zemu0faxxx:	btst		#BBC0_AENA,d6
		beq.s		zzemu0faxxx
		
		lea		(MintTrack,pc),a5
		addq.b		#$01,($0e,a5)
		moveq		#$01,d1

				
zzemu0faxxx:	tst.l		d1
;		beq.s		zemu0faxxxxx		
		
		lea		(MintTrack,pc),a5
		cmp.b		#$0f,d6
		beq.s		zemu0faxxxx
		
		subq.b		#$01,($0a,a5)
		bra		emu0fabadexit
		
zemu0faxxxx:	subq.b		#$01,($fa,a5)
zemu0faxxxxx:	bra		emu0fabadexit	







		exg.l		a5,d2
		lea		(MintTrack,pc),a5
		addq.b		#$01,($0b,a5)
		exg.l		a5,d2
		
		cmp.l		#$01,d6
		bne.s		demu0fas0			;--> >1.w 
		
		addq.l		#$02,a5				;a5- + modulo
		addq.l		#$02,d4				;d4- + modulo
		
		move.l		a5,d2
		neg.l		d2
		neg.l		d4
		move.l		d2,a5
		
		bra		emu0fa1wl
		
		
	;
	;two word loop
	;		
			
demu0fas0:	cmp.l		#$02,d6
		bne.s		demu0fas1			;--> >1.lw
		
		addq.l		#$04,a5				;a5- + modulo
		addq.l		#$04,d4
		
		subq.l		#$02,a1				;modify pntrs
		subq.l		#$02,a4
		
		move.l		a5,d2
		neg.l		d2
		neg.l		d4
		move.l		d2,a5
		
		bsr		emu0fa2wl
		
		addq.l		#$02,a1
		addq.l		#$02,a4
		
		rts
						
		
	;
	;multiple word loop
	;		
		
demu0fas1:	btst		#$00,d6
		bne.s		demu0faoww			;--> odd word width

		move.l		a5,d2
		btst		#$01,d2
		bne		emu0fabadexit			;--> odd word data width
				
		move.l		a4,d2
		moveq		#-2,d0
		move.l		d5,d3				;d3- fwm:lwm
		move.w		#$ffff,d3
		swap		d5
		move.w		d3,d5				;d5- lwm:ffff
		swap		d3				;d3- ffff:fwm
		
		btst		#$01,d2
		bne.s		demu0fas11			;--> start lw aligned				

		swap		d3
		moveq		#$00,d0
		sub.w		d3,d3				;d3- fwm:0000
		sub.w		d5,d5
		swap		d5				;d5- 0000:lwm
		addq.l		#$02,d6				;width + 1lw
		subq.l		#$04,a5				;correct modulo
		subq.l		#$04,d4
		bra.s		demu0fas11
		
demu0faoww:	move.l		a5,d2
		btst		#$01,d2
		beq.s		emu0fabadexit			;--> odd word data width
	
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
		bne.s		demu0fas11			;--> start lw aligned
		
		swap		d3
		swap		d5
		move.w		d3,d5				;d5- lwm:ffff
		clr.w		d3				;d3- fwm:0000
		moveq		#$00,d0

demu0fas11:	add.l		d6,d6
		add.l		d6,a5				;a5- bpr
		add.l		d6,d4

		neg.l		d4
		move.l		a5,d2
		neg.l		d2
		move.l		d2,a5
		
		lsr.l		#$02,d6				;d6- lw's
		subq.l		#$03,d6				;d6- # body lw's
		bpl		emu0famwl
		
		exg.l		d3,d5
		subq.l		#$04,a1
		subq.l		#$04,a4
		bsr		emu0famwl
		addq.l		#$04,a1
		addq.l		#$04,a4
		rts
	
		
emu0fagoodexit:	rts		

emu0fabadexit:	bra		emu16
