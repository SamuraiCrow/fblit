

	;
	;planes stuff (no data)
	;
	
	;
	;FillPlanes	(fill a rectangle)
	;<d0- destx.w (1st pixel in 1st lw)
	; d1- BTH
	; d2- flw.l (offset to 1st lw)
	; d3- destmod.l (row modulo for planes)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a4- *planes (pointer to array of *planes)
	; 
	;>
	;all reg's preserved
	;

FillPlanes:
		movem.l		d0-d2/d4-d7/a0-a4/a6,-(sp)
		
		move.w		d0,a1				;*auto extended*
		move.l		d1,a2
		move.l		d2,a3
				
	;one plane
			
FPonehead:
		tst.b		d1
		beq.s		FPonebody			;--> no head
		
		move.l		a1,d0
		move.l		(a4),a0				;a0- plane
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{d0:d1}			;d6- mask
		add.l		d2,a0				;a0- flw
		swap		d4				;d4- rows
FPohl1:
		move.l		d6,d0
		move.l		(a0),d5
		or.l		d5,d0
		add.l		d3,a0
		cmp.l		d5,d0
		dbne		d4,FPohl1
		
		beq.s		FPohx				;--> all done
		
		sub.l		d3,a0
		bra.s		FPohs1
FPohl2:
		move.l		(a0),d0
		or.l		d6,d0
FPohs1:				
		move.l		d0,(a0)		
		add.l		d3,a0	
		dbra		d4,FPohl2
FPohx:
		addq.l		#$04,d2
FPonebody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		FPonetail			;--> no body

		move.l		(a4),a0		
		move.l		d7,d4
		lea		(4,d1.w*4),a6
		moveq		#-1,d6
		add.l		a6,d2				;d2- next lw
		swap		d4				;d4- rows
		add.l		d2,a0
		add.l		d3,a6				;a6- mod
FPobl1:		
		move.w		d1,d5				;d5- #lw
FPobl2:
		move.l		d6,-(a0)
		dbra		d5,FPobl2
		
		add.l		a6,a0				;next row
		dbra		d4,FPobl1
FPonetail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		FPox				;--> no tail
		
		move.l		(a4),a0
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{0:d1}
		add.l		d2,a0
		swap		d4
FPotl1:
		move.l		d6,d0
		move.l		(a0),d5
		or.l		d5,d0
		add.l		d3,a0
		cmp.l		d5,d0
		dbne		d4,FPotl1
		
		beq.s		FPox				;--> all done
		
		sub.l		d3,a0
		bra.s		FPots1
FPotl2:
		move.l		(a0),d0
		or.l		d6,d0
FPots1:				
		move.l		d0,(a0)		
		add.l		d3,a0	
		dbra		d4,FPotl2
FPox:
		addq.l		#$04,a4				;a4- next planes
		move.l		a2,d1				;recover stuff
		move.l		a3,d2

		subq.b		#$01,d7
		bne		FPonehead		
FPx:
		movem.l		(sp)+,d0-d2/d4-d7/a0-a4/a6
		rts					
		
		
		
	;
	;ClearPlanes	(clear a rectangle)
	;<d0- destx.w (1st pixel in 1st lw)
	; d1- BTH
	; d2- flw.l (offset to 1st lw)
	; d3- destmod.l (row modulo for planes)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a4- *planes (pointer to array of *planes)
	; 
	;>
	;all reg's preserved
	;

ClearPlanes:
		movem.l		d0-d2/d4-d7/a0-a4/a6,-(sp)
		
		move.w		d0,a1
		move.l		d1,a2
		move.l		d2,a3

	;one plane
			
CPonehead:		
		tst.b		d1
		beq.s		CPonebody			;--> no head
		
		move.l		a1,d0
		move.l		(a4),a0				;a0- plane
		moveq		#-1,d6
		move.l		d7,d4
		bfclr		d6{d0:d1}			;d6- mask
		add.l		d2,a0				;a0- flw
		swap		d4				;d4- rows
CPohl1:
		move.l		d6,d0
		move.l		(a0),d5
		and.l		d5,d0
		add.l		d3,a0
		cmp.l		d5,d0
		dbne		d4,CPohl1
		
		beq.s		CPohx				;--> all done
		
		sub.l		d3,a0
		bra.s		CPohs1
CPohl2:
		move.l		(a0),d0
		and.l		d6,d0
CPohs1:				
		move.l		d0,(a0)		
		add.l		d3,a0	
		dbra		d4,CPohl2
CPohx:		
		addq.l		#$04,d2
CPonebody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		CPonetail			;--> no body

		move.l		(a4),a0		
		move.l		d7,d4
		lea		(4,d1.w*4),a6
		moveq		#00,d6
		add.l		a6,d2				;d2- next lw
		swap		d4				;d4- rows
		add.l		d2,a0
		add.l		d3,a6				;a6- mod
CPobl1:		
		move.w		d1,d5				;d5- #lw
CPobl2:
		move.l		d6,-(a0)
		dbra		d5,CPobl2
		
		add.l		a6,a0				;next row
		dbra		d4,CPobl1
CPonetail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		CPox				;--> no tail
		
		move.l		(a4),a0
		moveq		#-1,d6
		move.l		d7,d4
		bfclr		d6{0:d1}
		add.l		d2,a0
		swap		d4
CPotl1:
		move.l		d6,d0
		move.l		(a0),d5
		and.l		d5,d0
		add.l		d3,a0
		cmp.l		d5,d0
		dbne		d4,CPotl1
		
		beq.s		CPox				;--> all done
		
		sub.l		d3,a0
		bra.s		CPots1
CPotl2:
		move.l		(a0),d0
		and.l		d6,d0
CPots1:				
		move.l		d0,(a0)		
		add.l		d3,a0	
		dbra		d4,CPotl2
CPox:
		addq.l		#$04,a4				;a4- next planes
		move.l		a2,d1				;recover stuff
		move.l		a3,d2

		subq.b		#$01,d7
		bne		CPonehead		
CPx:
		movem.l		(sp)+,d0-d2/d4-d7/a0-a4/a6
		rts					
		



	;
	;CompPlanes	(complement a rectangle)
	;<d0- destx.w (1st pixel in 1st lw)
	; d1- BTH
	; d2- flw.l (offset to 1st lw)
	; d3- destmod.l (row modulo for planes)
	; d7- #rows-1.w:flags.b|#planes.b
	;
	; a4- *planes (pointer to array of *planes)
	; 
	;>
	;all reg's preserved
	;

CompPlanes:
		movem.l		d0-d2/d4-d7/a0-a4/a6,-(sp)
		
		ext.l		d0
		lsr.b		#$01,d7
		bcc.s		COPtwo				;--> no singles
		
	;one plane
			
COPonehead:		
		tst.b		d1
		beq.s		COPonebody			;--> no head
		
		move.l		(a4),a0				;a0- plane
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{d0:d1}			;d6- mask
		add.l		d2,a0				;a0- flw
		swap		d4				;d4- rows
COPohl1:
		eor.l		d6,(a0)
		add.l		d3,a0	
		dbra		d4,COPohl1
		
		addq.l		#$04,d2
COPonebody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COPonetail			;--> no body

		move.l		(a4),a0		
		move.l		d7,d4
		lea		(4,d1.w*4),a6
		add.l		a6,d2				;d2- next lw
		swap		d4				;d4- rows
		add.l		d2,a0
		add.l		d3,a6				;a6- mod
COPobl1:		
		move.w		d1,d5				;d5- #lw
COPobl2:
		not.l		-(a0)
		dbra		d5,COPobl2
		
		add.l		a6,a0				;next row
		dbra		d4,COPobl1
COPonetail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COPox				;--> no tail
		
		move.l		(a4),a0
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{0:d1}
		add.l		d2,a0
		swap		d4
COPotl1:
		eor.l		d6,(a0)
		add.l		d3,a0
		dbra		d4,COPotl1
COPox:
		addq.l		#$04,a4				;a4- next planes
		movem.l		(4,sp),d1-d2			;recover stuff

	;two planes
			
COPtwo:		
		lsr.b		#$01,d7
		bcc		COPfour				;--> no doubles
COPtwohead:		
		tst.b		d1
		beq.s		COPtwobody			;--> no head
		
		movem.l		(a4),a0/a1			;a0/a1- planes
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{d0:d1}			;d6- mask
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		swap		d4				;d4- rows
COPthl1:
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		add.l		d3,a0
		add.l		d3,a1
		dbra		d4,COPthl1
		
		addq.l		#$04,d2
COPtwobody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COPtwotail			;--> no body

		movem.l		(a4),a0/a1
		move.l		d7,d4
		lea		(4,d1.w*4),a6
		add.l		a6,d2				;d2- next lw
		swap		d4				;d4- rows
		add.l		d2,a0
		add.l		d2,a1
		add.l		d3,a6				;a6- mod
COPtbl1:		
		move.w		d1,d5				;d5- #lw
COPtbl2:
		not.l		-(a0)
		not.l		-(a1)
		dbra		d5,COPtbl2
		
		add.l		a6,a0				;next row
		add.l		a6,a1
		dbra		d4,COPtbl1
COPtwotail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COPtx				;--> no tail
		
		movem.l		(a4),a0/a1
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{0:d1}
		add.l		d2,a0
		add.l		d2,a1
		swap		d4
COPttl1:
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		add.l		d3,a0
		add.l		d3,a1
		dbra		d4,COPttl1
COPtx:
		addq.l		#$08,a4				;a4- next planes
		movem.l		(4,sp),d1-d2			;recover stuff
		bra		COPfour

	;four planes
	
COPfourhead:		
		tst.b		d1
		beq.s		COPfourbody			;--> no head
		
		movem.l		(a4),a0-a3			;a0-a3- plane
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{d0:d1}			;d6- mask
		add.l		d2,a0				;a0- flw
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		swap		d4				;d4- rows
COPfhl1:
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		eor.l		d6,(a2)
		eor.l		d6,(a3)
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3	
		dbra		d4,COPfhl1
		
		addq.l		#$04,d2
COPfourbody:
		swap		d1
		subq.w		#$01,d1
		bmi.s		COPfourtail			;--> no body

		movem.l		(a4),a0-a3
		move.l		d7,d4
		lea		(4,d1.w*4),a6
		moveq		#-1,d6
		add.l		a6,d2				;d2- next lw
		swap		d4				;d4- rows
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		add.l		d3,a6				;a6- mod
COPfbl1:		
		move.w		d1,d5				;d5- #lw
COPfbl2:
		not.l		-(a0)
		not.l		-(a1)
		not.l		-(a2)
		not.l		-(a3)
		dbra		d5,COPfbl2
		
		add.l		a6,a0				;next row
		add.l		a6,a1
		add.l		a6,a2
		add.l		a6,a3
		dbra		d4,COPfbl1
COPfourtail:
		rol.l		#$08,d1
		tst.b		d1
		beq.s		COPfx				;--> no tail
		
		movem.l		(a4),a0-a3
		moveq		#$00,d6
		move.l		d7,d4
		bfset		d6{0:d1}
		add.l		d2,a0
		add.l		d2,a1
		add.l		d2,a2
		add.l		d2,a3
		swap		d4
COPftl1:
		eor.l		d6,(a0)
		eor.l		d6,(a1)
		eor.l		d6,(a2)
		eor.l		d6,(a3)
		add.l		d3,a0
		add.l		d3,a1
		add.l		d3,a2
		add.l		d3,a3
		dbra		d4,COPftl1
COPfx:
		add.w		#$10,a4				;a4- next planes 
								;(***auto word extension!***)
		movem.l		(4,sp),d1-d2			;recover stuff
COPfour:		
		dbra		d7,COPfourhead		
COPx:
		movem.l		(sp)+,d0-d2/d4-d7/a0-a4/a6
		rts					
		
		
			