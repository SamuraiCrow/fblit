

	;
	;FillTemplatePlanes	(set mask 1's in all planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a4- *planes (pointer to array of *planes)
	; a5- *mask (pointer to 1st lw in 2d array)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert mask)
	;

FillTemplatePlanes:

		movem.l		d0-d7/a0-a6,-(sp)
			
		lsr.b		#$01,d7
		bcc		FTPnatwo			;--> no singles

	;one plane
			
FTPnaonehead:	
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		FTPnaonebody			;--> no head
		
		move.l		(a4),a0				;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		clr.w		d5				;d5- maskax:0000
		add.l		d2,a0				;a0- flw
		swap		d5				;d5- maskax
		moveq		#$00,d2
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnaohl2			;--> complement
FTPnaohl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		or.l		d2,(a0)
		add.l		d4,a6
		add.l		d3,a0	
		dbra		d7,FTPnaohl1
		
		bra.s		FTPnaohx
FTPnaohl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		or.l		d2,(a0)
		add.l		d4,a6
		add.l		d3,a0
		dbra		d7,FTPnaohl2
FTPnaohx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0			;recover start
FTPnaonebody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		FTPnaonetail			;--> no body

		move.l		(a4),a0		
		clr.w		d0		
		lea		(4,d1.w*4),a6
		swap		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnaobl3			;--> complement
FTPnaobl1:		
		move.w		d1,d3				;d4- #lw
FTPnaobl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		or.l		d5,-(a0)
		dbra		d3,FTPnaobl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		dbra		d7,FTPnaobl1
		
		bra.s		FTPnaobx
FTPnaobl3:
		move.w		d1,d3
FTPnaobl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		or.l		d5,-(a0)
		dbra		d3,FTPnaobl4
		
		add.l		d4,a5
		add.l		a6,a0
		dbra		d7,FTPnaobl3
FTPnaobx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
FTPnaonetail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		FTPnaox				;--> no tail
		
		move.l		(a4),a0
		swap		d0
		add.l		d2,a0
		ext.l		d0
		moveq		#$00,d6
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnaotl2			;--> complement
FTPnaotl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		or.l		d6,(a0)
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,FTPnaotl1
		
		bra.s		FTPnaox
FTPnaotl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		or.l		d6,(a0)
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,FTPnaotl2		
FTPnaox:
		move.w		($1c,sp),d7
		addq.l		#$04,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

	;two planes		
		
FTPnatwo:		
		lsr.b		#$01,d7
		bcc		FTPnafour			;--> no double
FTPnatwohead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		FTPnatwobody			;--> no head
		
		movem.l		(a4),a0/a1			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		ext.l		d5				;d5- maskax
		moveq		#$00,d2
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnathl2			;--> complement
FTPnathl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		or.l		d2,(a0)
		or.l		d2,(a1)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1	
		dbra		d7,FTPnathl1
		
		bra.s		FTPnathx
FTPnathl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		or.l		d2,(a0)
		or.l		d2,(a1)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,FTPnathl2
FTPnathx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0			;recover start
FTPnatwobody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		FTPnatwotail			;--> no body

		movem.l		(a4),a0/a1		
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		add.l		d2,a1
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnatbl3			;--> complement
FTPnatbl1:		
		move.w		d1,d3				;d4- #lw
FTPnatbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		or.l		d5,-(a0)
		or.l		d5,-(a1)
		dbra		d3,FTPnatbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		dbra		d7,FTPnatbl1
		
		bra.s		FTPnatbx
FTPnatbl3:
		move.w		d1,d3
FTPnatbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		or.l		d5,-(a0)
		or.l		d5,-(a1)
		dbra		d3,FTPnatbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		dbra		d7,FTPnatbl3
FTPnatbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
FTPnatwotail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		FTPnatx				;--> no tail
		
		movem.l		(a4),a0/a1
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		ext.l		d0
		moveq		#$00,d6
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnattl2			;--> complement
FTPnattl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		or.l		d6,(a0)
		or.l		d6,(a1)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,FTPnattl1
		
		bra.s		FTPnatx
FTPnattl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		or.l		d6,(a0)
		or.l		d6,(a1)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,FTPnattl2		
FTPnatx:
		move.w		($1c,sp),d7
		addq.l		#$08,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5
		bra		FTPnafour
	
	;four
	
FTPnafourhead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		FTPnafourbody			;--> no head
		
		movem.l		(a4),a0-a3			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d5				;d5- maskax
		moveq		#$00,d2
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnafhl2			;--> complement
FTPnafhl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		or.l		d2,(a0)
		or.l		d2,(a1)
		or.l		d2,(a2)
		or.l		d2,(a3)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3	
		dbra		d7,FTPnafhl1
		
		bra.s		FTPnafhx
FTPnafhl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		or.l		d2,(a0)
		or.l		d2,(a1)
		or.l		d2,(a2)
		or.l		d2,(a3)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,FTPnafhl2
FTPnafhx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0				;recover start
FTPnafourbody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		FTPnafourtail			;--> no body

		movem.l		(a4),a0-a3
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnafbl3			;--> complement
FTPnafbl1:		
		move.w		d1,d3				;d4- #lw
FTPnafbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		or.l		d5,-(a0)
		or.l		d5,-(a1)
		or.l		d5,-(a2)
		or.l		d5,-(a3)
		dbra		d3,FTPnafbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,FTPnafbl1
		
		bra.s		FTPnafbx
FTPnafbl3:
		move.w		d1,d3
FTPnafbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		or.l		d5,-(a0)
		or.l		d5,-(a1)
		or.l		d5,-(a2)
		or.l		d5,-(a3)
		dbra		d3,FTPnafbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,FTPnafbl3
FTPnafbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
FTPnafourtail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		FTPnafx				;--> no tail
		
		movem.l		(a4),a0-a3
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d0
		moveq		#$00,d6
		btst		#FB_INVERSVID+$18,d7
		bne.s		FTPnaftl2			;--> complement
FTPnaftl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		or.l		d6,(a0)
		or.l		d6,(a1)
		or.l		d6,(a2)
		or.l		d6,(a3)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,FTPnaftl1
		
		bra.s		FTPnafx
FTPnaftl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		or.l		d6,(a0)
		or.l		d6,(a1)
		or.l		d6,(a2)
		or.l		d6,(a3)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,FTPnaftl2		
FTPnafx:
		move.w		($1c,sp),d7
		add.w		#$10,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

FTPnafour:
		subq.b		#$01,d7
		bpl		FTPnafourhead
	
FTPx:
		movem.l		(sp)+,d0-d7/a0-a6		
		rts
	
	
		
	;
	;ClearTemplatePlanes	(clear all mask 1's in planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a4- *planes (pointer to array of *planes)
	; a5- *mask (pointer to 1st lw in 2d array)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert mask)
	;

ClearTemplatePlanes:

		movem.l		d0-d7/a0-a6,-(sp)
		
		lsr.b		#$01,d7
		bcc		CTPnatwo			;--> no singles

	;one plane
			
CTPnaonehead:	
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		CTPnaonebody			;--> no head
		
		move.l		(a4),a0				;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		ext.l		d5				;d5- maskax
		moveq		#-1,d2
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnaohl2			;--> not complement
CTPnaohl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		and.l		d2,(a0)
		add.l		d4,a6
		add.l		d3,a0	
		dbra		d7,CTPnaohl1
		
		bra.s		CTPnaohx
CTPnaohl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		and.l		d2,(a0)
		add.l		d4,a6
		add.l		d3,a0
		dbra		d7,CTPnaohl2
CTPnaohx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0			;recover start
CTPnaonebody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CTPnaonetail			;--> no body

		move.l		(a4),a0		
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnaobl3			;--> not complement
CTPnaobl1:		
		move.w		d1,d3				;d4- #lw
CTPnaobl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		and.l		d5,-(a0)
		dbra		d3,CTPnaobl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		dbra		d7,CTPnaobl1
		
		bra.s		CTPnaobx
CTPnaobl3:
		move.w		d1,d3
CTPnaobl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		and.l		d5,-(a0)
		dbra		d3,CTPnaobl4
		
		add.l		d4,a5
		add.l		a6,a0
		dbra		d7,CTPnaobl3
CTPnaobx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
CTPnaonetail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CTPnaox				;--> no tail
		
		move.l		(a4),a0
		swap		d0
		add.l		d2,a0
		ext.l		d0
		moveq		#-1,d6
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnaotl2			;--> not complement
CTPnaotl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		and.l		d6,(a0)
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,CTPnaotl1
		
		bra.s		CTPnaox
CTPnaotl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		and.l		d6,(a0)
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,CTPnaotl2		
CTPnaox:
		move.w		($1c,sp),d7
		addq.l		#$04,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

	;two planes		
		
CTPnatwo:		
		lsr.b		#$01,d7
		bcc		CTPnafour			;--> no double
CTPnatwohead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		CTPnatwobody			;--> no head
		
		movem.l		(a4),a0/a1			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		ext.l		d5				;d5- maskax
		moveq		#-1,d2
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnathl2			;--> not complement
CTPnathl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		and.l		d2,(a0)
		and.l		d2,(a1)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1	
		dbra		d7,CTPnathl1
		
		bra.s		CTPnathx
CTPnathl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		and.l		d2,(a0)
		and.l		d2,(a1)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,CTPnathl2
CTPnathx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0			;recover start
CTPnatwobody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CTPnatwotail			;--> no body

		movem.l		(a4),a0/a1		
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		add.l		d2,a1
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnatbl3			;--> not complement
CTPnatbl1:		
		move.w		d1,d3				;d4- #lw
CTPnatbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		and.l		d5,-(a0)
		and.l		d5,-(a1)
		dbra		d3,CTPnatbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		dbra		d7,CTPnatbl1
		
		bra.s		CTPnatbx
CTPnatbl3:
		move.w		d1,d3
CTPnatbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		and.l		d5,-(a0)
		and.l		d5,-(a1)
		dbra		d3,CTPnatbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		dbra		d7,CTPnatbl3
CTPnatbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
CTPnatwotail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CTPnatx				;--> no tail
		
		movem.l		(a4),a0/a1
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		ext.l		d0
		moveq		#-1,d6
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnattl2			;--> not complement
CTPnattl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		and.l		d6,(a0)
		and.l		d6,(a1)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,CTPnattl1
		
		bra.s		CTPnatx
CTPnattl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		and.l		d6,(a0)
		and.l		d6,(a1)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,CTPnattl2		
CTPnatx:
		move.w		($1c,sp),d7
		addq.l		#$08,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5
		bra		CTPnafour
	
	;four
	
CTPnafourhead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		CTPnafourbody			;--> no head
		
		movem.l		(a4),a0-a3			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d5				;d5- maskax
		moveq		#-1,d2
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnafhl2			;--> not complement
CTPnafhl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		and.l		d2,(a0)
		and.l		d2,(a1)
		and.l		d2,(a2)
		and.l		d2,(a3)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3	
		dbra		d7,CTPnafhl1
		
		bra.s		CTPnafhx
CTPnafhl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		and.l		d2,(a0)
		and.l		d2,(a1)
		and.l		d2,(a2)
		and.l		d2,(a3)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,CTPnafhl2
CTPnafhx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0			;recover start
CTPnafourbody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CTPnafourtail			;--> no body

		movem.l		(a4),a0-a3
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnafbl3			;--> not complement
CTPnafbl1:		
		move.w		d1,d3				;d4- #lw
CTPnafbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		and.l		d5,-(a0)
		and.l		d5,-(a1)
		and.l		d5,-(a2)
		and.l		d5,-(a3)
		dbra		d3,CTPnafbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,CTPnafbl1
		
		bra.s		CTPnafbx
CTPnafbl3:
		move.w		d1,d3
CTPnafbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		and.l		d5,-(a0)
		and.l		d5,-(a1)
		and.l		d5,-(a2)
		and.l		d5,-(a3)
		dbra		d3,CTPnafbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,CTPnafbl3
CTPnafbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
CTPnafourtail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CTPnafx				;--> no tail
		
		movem.l		(a4),a0-a3
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d0
		moveq		#-1,d6
		btst		#FB_INVERSVID+$18,d7
		beq.s		CTPnaftl2			;--> not complement
CTPnaftl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		and.l		d6,(a0)
		and.l		d6,(a1)
		and.l		d6,(a2)
		and.l		d6,(a3)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,CTPnaftl1
		
		bra.s		CTPnafx
CTPnaftl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		and.l		d6,(a0)
		and.l		d6,(a1)
		and.l		d6,(a2)
		and.l		d6,(a3)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,CTPnaftl2		
CTPnafx:
		move.w		($1c,sp),d7
		add.w		#$10,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

CTPnafour:
		subq.b		#$01,d7
		bpl		CTPnafourhead
	
CTPx:
		movem.l		(sp)+,d0-d7/a0-a6	
		rts

		
	;
	;CopyTemplatePlanes	(copy mask to planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a4- *planes (pointer to array of *planes)
	; a5- *mask (pointer to 1st lw in 2d array)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert mask)
	;

CopyTemplatePlanes:

		movem.l		d0-d7/a0-a6,-(sp)
		
		lsr.b		#$01,d7
		bcc		COPTPnatwo			;--> no singles

	;one plane
			
COPTPnaonehead:	
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		COPTPnaonebody			;--> no head
		
		move.l		(a4),a0				;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		ext.l		d5				;d5- maskax
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnaohl2			;--> complement
COPTPnaohl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,(a0){d0:d1}
		add.l		d4,a6
		add.l		d3,a0	
		dbra		d7,COPTPnaohl1
		
		bra.s		COPTPnaohx
COPTPnaohl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,(a0){d0:d1}
		add.l		d4,a6
		add.l		d3,a0
		dbra		d7,COPTPnaohl2
COPTPnaohx:		
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0				;recover start
COPTPnaonebody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COPTPnaonetail			;--> no body

		move.l		(a4),a0		
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d2,a0
		add.l		d3,a6				;a6- dest mod
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnaobl3			;--> complement
COPTPnaobl1:		
		move.w		d1,d3				;d4- #lw
COPTPnaobl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		move.l		d5,-(a0)
		dbra		d3,COPTPnaobl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		dbra		d7,COPTPnaobl1
		
		bra.s		COPTPnaobx
COPTPnaobl3:
		move.w		d1,d3
COPTPnaobl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		move.l		d5,-(a0)
		dbra		d3,COPTPnaobl4
		
		add.l		d4,a5
		add.l		a6,a0
		dbra		d7,COPTPnaobl3
COPTPnaobx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
COPTPnaonetail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COPTPnaox				;--> no tail
		
		move.l		(a4),a0
		swap		d0
		add.l		d2,a0
		ext.l		d0
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnaotl2			;--> complement
COPTPnaotl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,(a0){0:d1}
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,COPTPnaotl1
		
		bra.s		COPTPnaox
COPTPnaotl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,(a0){0:d1}
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,COPTPnaotl2		
COPTPnaox:
		move.w		($1c,sp),d7
		addq.l		#$04,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

	;two planes		
		
COPTPnatwo:		
		lsr.b		#$01,d7
		bcc		COPTPnafour			;--> no double
COPTPnatwohead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		COPTPnatwobody			;--> no head
		
		movem.l		(a4),a0/a1			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		ext.l		d5				;d5- maskax
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnathl2			;--> complement
COPTPnathl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,(a0){d0:d1}
		bfins		d6,(a1){d0:d1}
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1	
		dbra		d7,COPTPnathl1
		
		bra.s		COPTPnathx
COPTPnathl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,(a0){d0:d1}
		bfins		d6,(a1){d0:d1}
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,COPTPnathl2
COPTPnathx:		
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0				;recover start
COPTPnatwobody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COPTPnatwotail			;--> no body

		movem.l		(a4),a0/a1		
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		add.l		d2,a1
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnatbl3			;--> complement
COPTPnatbl1:		
		move.w		d1,d3				;d4- #lw
COPTPnatbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		move.l		d5,-(a0)
		move.l		d5,-(a1)
		dbra		d3,COPTPnatbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		dbra		d7,COPTPnatbl1
		
		bra.s		COPTPnatbx
COPTPnatbl3:
		move.w		d1,d3
COPTPnatbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		move.l		d5,-(a0)
		move.l		d5,-(a1)
		dbra		d3,COPTPnatbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		dbra		d7,COPTPnatbl3
COPTPnatbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
COPTPnatwotail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COPTPnatx				;--> no tail
		
		movem.l		(a4),a0/a1
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		ext.l		d0
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnattl2			;--> complement
COPTPnattl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,(a0){0:d1}
		bfins		d5,(a1){0:d1}
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,COPTPnattl1
		
		bra.s		COPTPnatx
COPTPnattl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,(a0){0:d1}
		bfins		d5,(a1){0:d1}
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,COPTPnattl2		
COPTPnatx:
		move.w		($1c,sp),d7
		addq.l		#$08,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5
		bra		COPTPnafour
	
	;four
	
COPTPnafourhead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		COPTPnafourbody			;--> no head
		
		movem.l		(a4),a0-a3			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d5				;d5- maskax
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnafhl2			;--> complement
COPTPnafhl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,(a0){d0:d1}
		bfins		d6,(a1){d0:d1}
		bfins		d6,(a2){d0:d1}
		bfins		d6,(a3){d0:d1}
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3	
		dbra		d7,COPTPnafhl1
		
		bra.s		COPTPnafhx
COPTPnafhl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,(a0){d0:d1}
		bfins		d6,(a1){d0:d1}
		bfins		d6,(a2){d0:d1}
		bfins		d6,(a3){d0:d1}
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,COPTPnafhl2
COPTPnafhx:		
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0				;recover start
COPTPnafourbody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COPTPnafourtail			;--> no body

		movem.l		(a4),a0-a3
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		add.l		d3,a6				;a6- dest mod
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnafbl3			;--> complement
COPTPnafbl1:		
		move.w		d1,d3				;d4- #lw
COPTPnafbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		move.l		d5,-(a0)
		move.l		d5,-(a1)
		move.l		d5,-(a2)
		move.l		d5,-(a3)
		dbra		d3,COPTPnafbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,COPTPnafbl1
		
		bra.s		COPTPnafbx
COPTPnafbl3:
		move.w		d1,d3
COPTPnafbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		move.l		d5,-(a0)
		move.l		d5,-(a1)
		move.l		d5,-(a2)
		move.l		d5,-(a3)
		dbra		d3,COPTPnafbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,COPTPnafbl3
COPTPnafbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
COPTPnafourtail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COPTPnafx				;--> no tail
		
		movem.l		(a4),a0-a3
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d0
		btst		#FB_INVERSVID+$18,d7
		bne.s		COPTPnaftl2			;--> complement
COPTPnaftl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,(a0){0:d1}
		bfins		d5,(a1){0:d1}
		bfins		d5,(a2){0:d1}
		bfins		d5,(a3){0:d1}
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,COPTPnaftl1
		
		bra.s		COPTPnafx
COPTPnaftl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,(a0){0:d1}
		bfins		d5,(a1){0:d1}
		bfins		d5,(a2){0:d1}
		bfins		d5,(a3){0:d1}
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,COPTPnaftl2		
COPTPnafx:
		move.w		($1c,sp),d7
		add.w		#$10,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

COPTPnafour:
		subq.b		#$01,d7
		bpl		COPTPnafourhead
	
COPTPx:
		movem.l		(sp)+,d0-d7/a0-a6		
		rts

	
	
	
	;
	;CompTemplatePlanes	(complement all mask 1's in planes)
	;<d0- maskx.w:destx.w (1st pixel in 1st lw (must be <32))
	; d1- BTH
	; d2- flw.l (offset to 1st dest lw)
	; d3- destmod.l (row modulos)
	; d4- maskmod.l
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a4- *planes (pointer to array of *planes)
	; a5- *mask (pointer to 1st lw in 2d array)
	; 
	;>
	;all reg's preserved
	;
	;flags-	FB_INVERSVID		(invert mask)
	;

CompTemplatePlanes:
		movem.l		d0-d7/a0-a6,-(sp)
			
		lsr.b		#$01,d7
		bcc		COMTPnatwo			;--> no singles
		
	;one plane
			
COMTPnaonehead:	
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		COMTPnaonebody			;--> no head
		
		move.l		(a4),a0				;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		clr.w		d5				;d5- maskax:0000
		add.l		d2,a0				;a0- flw
		swap		d5				;d5- maskax
		moveq		#$00,d2
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnaohl2			;--> complement
COMTPnaohl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		eor.l		d2,(a0)
		add.l		d4,a6
		add.l		d3,a0	
		dbra		d7,COMTPnaohl1
		
		bra.s		COMTPnaohx
COMTPnaohl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		eor.l		d2,(a0)
		add.l		d4,a6
		add.l		d3,a0
		dbra		d7,COMTPnaohl2
COMTPnaohx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0			;recover start
COMTPnaonebody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COMTPnaonetail			;--> no body

		move.l		(a4),a0		
		clr.w		d0		
		lea		(4,d1.w*4),a6
		swap		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnaobl3			;--> complement
COMTPnaobl1:		
		move.w		d1,d3				;d4- #lw
COMTPnaobl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		eor.l		d5,-(a0)
		dbra		d3,COMTPnaobl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		dbra		d7,COMTPnaobl1
		
		bra.s		COMTPnaobx
COMTPnaobl3:
		move.w		d1,d3
COMTPnaobl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		eor.l		d5,-(a0)
		dbra		d3,COMTPnaobl4
		
		add.l		d4,a5
		add.l		a6,a0
		dbra		d7,COMTPnaobl3
COMTPnaobx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
COMTPnaonetail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COMTPnaox				;--> no tail
		
		move.l		(a4),a0
		swap		d0
		add.l		d2,a0
		ext.l		d0
		moveq		#$00,d6
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnaotl2			;--> complement
COMTPnaotl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		eor.l		d6,(a0)
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,COMTPnaotl1
		
		bra.s		COMTPnaox
COMTPnaotl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		eor.l		d6,(a0)
		add.l		d4,a5
		add.l		d3,a0
		dbra		d7,COMTPnaotl2		
COMTPnaox:
		move.w		($1c,sp),d7
		addq.l		#$04,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

	;two planes		
		
COMTPnatwo:		
		lsr.b		#$01,d7
		bcc		COMTPnafour			;--> no double
COMTPnatwohead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		COMTPnatwobody			;--> no head
		
		movem.l		(a4),a0/a1			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		ext.l		d5				;d5- maskax
		moveq		#$00,d2
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnathl2			;--> complement
COMTPnathl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		eor.l		d2,(a0)
		eor.l		d2,(a1)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1	
		dbra		d7,COMTPnathl1
		
		bra.s		COMTPnathx
COMTPnathl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		eor.l		d2,(a0)
		eor.l		d2,(a1)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,COMTPnathl2
COMTPnathx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0			;recover start
COMTPnatwobody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COMTPnatwotail			;--> no body

		movem.l		(a4),a0/a1		
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		add.l		d2,a1
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnatbl3			;--> complement
COMTPnatbl1:		
		move.w		d1,d3				;d4- #lw
COMTPnatbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		eor.l		d5,-(a0)
		eor.l		d5,-(a1)
		dbra		d3,COMTPnatbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		dbra		d7,COMTPnatbl1
		
		bra.s		COMTPnatbx
COMTPnatbl3:
		move.w		d1,d3
COMTPnatbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		eor.l		d5,-(a0)
		eor.l		d5,-(a1)
		dbra		d3,COMTPnatbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		dbra		d7,COMTPnatbl3
COMTPnatbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
COMTPnatwotail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COMTPnatx				;--> no tail
		
		movem.l		(a4),a0/a1
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		ext.l		d0
		moveq		#$00,d6
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnattl2			;--> complement
COMTPnattl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,COMTPnattl1
		
		bra.s		COMTPnatx
COMTPnattl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		dbra		d7,COMTPnattl2		
COMTPnatx:
		move.w		($1c,sp),d7
		addq.l		#$08,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5
		bra		COMTPnafour
	
	;four
	
COMTPnafourhead:		
		swap		d7				;d7- flags|#planes:rows
		tst.b		d1
		beq.s		COMTPnafourbody			;--> no head
		
		movem.l		(a4),a0-a3			;a0- plane
		move.l		a5,a6				;a6- *mask flw
		move.l		d0,d5				;d5- maskax:destax
		ext.l		d0				;d0- destax
		move.l		d2,-(sp)
		swap		d5				;d5- destax:maskax
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d5				;d5- maskax
		moveq		#$00,d2
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnafhl2			;--> complement
COMTPnafhl1:
		bfextu		(a6){d5:d1},d6
		bfins		d6,d2{d0:d1}
		eor.l		d2,(a0)
		eor.l		d2,(a1)
		eor.l		d2,(a2)
		eor.l		d2,(a3)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3	
		dbra		d7,COMTPnafhl1
		
		bra.s		COMTPnafhx
COMTPnafhl2:		
		bfextu		(a6){d5:d1},d6
		not.l		d6
		bfins		d6,d2{d0:d1}
		eor.l		d2,(a0)
		eor.l		d2,(a1)
		eor.l		d2,(a2)
		eor.l		d2,(a3)
		add.l		d4,a6
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,COMTPnafhl2
COMTPnafhx:		
		move.l		(sp)+,d2
		add.b		d1,d5
		move.w		($1c,sp),d7			;recover rows
		swap		d5
		addq.l		#$04,d2
		move.l		d5,d0
		move.w		(2,sp),d0				;recover start
COMTPnafourbody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COMTPnafourtail			;--> no body

		movem.l		(a4),a0-a3
		swap		d0		
		lea		(4,d1.w*4),a6
		ext.l		d0				;d0- maskx
		move.l		a5,d6				;d6- *mask
		add.l		a6,d2				;d2- next dest lw
		add.l		a6,d6				;d6- next mask lw
		add.l		d3,a6				;a6- dest mod
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnafbl3			;--> complement
COMTPnafbl1:		
		move.w		d1,d3				;d4- #lw
COMTPnafbl2:
		bfextu		(a5,d3.w*4){d0:32},d5
		eor.l		d5,-(a0)
		eor.l		d5,-(a1)
		eor.l		d5,-(a2)
		eor.l		d5,-(a3)
		dbra		d3,COMTPnafbl2
		
		add.l		d4,a5
		add.l		a6,a0				;next row
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,COMTPnafbl1
		
		bra.s		COMTPnafbx
COMTPnafbl3:
		move.w		d1,d3
COMTPnafbl4:
		bfextu		(a5,d3.w*4){d0:32},d5						
		not.l		d5
		eor.l		d5,-(a0)
		eor.l		d5,-(a1)
		eor.l		d5,-(a2)
		eor.l		d5,-(a3)
		dbra		d3,COMTPnafbl4
		
		add.l		d4,a5
		add.l		a6,a0
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d7,COMTPnafbl3
COMTPnafbx:
		move.l		($0c,sp),d3
		move.l		d6,a5
		swap		d0
		move.w		($1c,sp),d7
		move.w		(2,sp),d0
COMTPnafourtail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COMTPnafx				;--> no tail
		
		movem.l		(a4),a0-a3
		swap		d0
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		ext.l		d0
		moveq		#$00,d6
		btst		#FB_INVERSVID+$18,d7
		bne.s		COMTPnaftl2			;--> complement
COMTPnaftl1:
		bfextu		(a5){d0:d1},d5
		bfins		d5,d6{0:d1}
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		eor.l		d6,(a2)
		eor.l		d6,(a3)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,COMTPnaftl1
		
		bra.s		COMTPnafx
COMTPnaftl2:
		bfextu		(a5){d0:d1},d5
		not.l		d5
		bfins		d5,d6{0:d1}
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		eor.l		d6,(a2)
		eor.l		d6,(a3)
		add.l		d4,a5
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d7,COMTPnaftl2		
COMTPnafx:
		move.w		($1c,sp),d7
		add.w		#$10,a4				;a4- next planes
		movem.l		(sp),d0-d2			;recover stuff
		swap		d7
		move.l		($34,sp),a5

COMTPnafour:
		subq.b		#$01,d7
		bpl		COMTPnafourhead
	
COMTPx:
		movem.l		(sp)+,d0-d7/a0-a6		
		rts
	

