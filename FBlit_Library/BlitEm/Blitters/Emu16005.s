

*-----------------------------------------------------------------------------
*
*	Emu16005.s V0.05 15.12.98
*
*	© Stephen Brookes 1997-98
*
*	16bit full emulation
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



emu16:		move.w		(bec_bltcon1,a0),d0
		btst		#BBC1_LINE,d0
		bne		bombout				;--> line mode, exit
		
		btst		#BBC1_DESC,d0
		bne		emu16desc			;--> descend



	;16bit full ascend mode

		move.l		(w_BShift,a0),a6		;a6-Bsh:Ash	
		subq.l		#$01,(l_Width,a0)
		sub.l		a5,a5				;a5-0:0 (last A:B)
	
rowloop:	move.w		(w_AFWM,a0),d7			;d7-xxxx:Afwm
		move.l		(l_Width,a0),d3			;d3-count
	
mainword:	and.w		(a1),d7				;d7-xxxx:A
		move.l		a6,d6				;d6-Bsh:Ash
		move.w		a5,d1				;d1-xxxx:last B
		move.l		a5,d0				;d0-last A:xxxx
		swap		d1				;d1-last B:xxxx
		move.w		d7,d0				;d0-last A:A	
		lsr.l		d6,d0				;shift A
		swap		d7				;d7-new last A:xxxx

		move.w		(a2),d1				;d1-last B:B
		move.w		d0,d5				;d5-xxxx:A
		swap		d6				;d6-xxxx:Bsh
		swap		d0				;d0-A:xxxx
		move.w		d1,d7				;d7-new last A:new last B
		move.w		d5,d0				;d0-A:A
		lsr.l		d6,d1				;shift B
		
		move.w		(a3),d2				;d2-xxxx:C
		move.w		d1,d5				;d5-xxxx:B
		move.l		d7,a5				;a5-last A:B
		swap		d1				;d1-B:xxxx
		
		move.l		(w_Amod,a0),d4			;d4-amod:bmod
		move.w		d5,d1				;d1-B:B
		move.w		d2,d6				;d6-xxxx:C
		add.w		(w_Cmod,a0),a3			;next C
		swap		d2				;d2-C:xxxx
		add.w		d4,a2				;next B
		move.w		d6,d2				;d2-C:C
		swap		d4				;d4-xxxx:amod
		not.w		d2				;d2-C:~C
		add.w		d4,a1				;next A

		movem.l		(s_Mintstore,a0),d4-d7		;fetch mint (d4/7-mint0/7)

		and.l		d0,d6				;d6- 4:5 & A:A
		and.l		d0,d7				;d7- 6:7 & A:A
		
		and.l		d1,d5				;d5- 2:3 & B:B
		not.l		d0				;d0- ~A:~A
		and.l		d1,d7				;d7- 6:7 & B:B
		
		and.l		d0,d4				;d4- 0:1 & ~A:~A
		not.l		d1				;d1- ~B:~B
		and.l		d0,d5				;d5- 2:3 & ~A:~A

		or.l		d6,d4				;d4- 0|4:1|5
		or.l		d5,d7				;d7- 2|6:3|7
		and.l		d1,d4				;d4- 0|4:1|5 & ~B:~B
		or.l		d7,d4				;d4- 0|2|4|6:1|3|5|7
		and.l		d2,d4				;&   ~C     :C
		move.w		d4,d5
		swap		d4
		or.w		d5,d4				;d4-D
		
		move.w		d4,(a4)+			;write...
		
		moveq		#-1,d7				;d7-xxxx:ffff
		
		subq.l		#$01,d3
		bhi		mainword			;--> not last word
		bcs.s		nextrow				;--> done and dusted
		
		move.w		(w_ALWM,a0),d7			;d7-xxxx:Alwm
		bra		mainword

nextrow:	move.l		(w_CRmod,a0),d0			;d0-crmod:brmod
		move.l		(w_ARmod,a0),d1			;d1-armod:drmod
		add.w		d0,a2
		swap		d0
		add.w		d0,a3
		add.w		d1,a4
		swap		d1
		add.w		d1,a1
		
		subq.l		#$01,(l_Rows,a0)
		bpl		rowloop
		
bombout:	rts
		
		
		
		
	;16bit full descend mode

emu16desc:	move.l		(w_BShift,a0),a6		;a6-Bsh:Ash	
		subq.l		#$01,(l_Width,a0)
		addq.l		#$02,a4
		sub.l		a5,a5
	
drowloop:	move.w		(w_AFWM,a0),d7			;d7-xxxx:Afwm
		move.l		(l_Width,a0),d3			;d3-count
	
dmainword:	and.w		(a1),d7				;d7-xxxx:A
		move.l		a6,d6				;d6-Bsh:Ash
		move.w		a5,d1				;d1-xxxx:last B
		move.l		a5,d0				;d0-last A:xxxx
		swap		d1				;d1-last B:xxxx
		move.w		d7,d0				;d0-last A:A	
		rol.l		d6,d0				;shift A
		swap		d7				;d7-new last A:xxxx

		move.w		(a2),d1				;d1-last B:B
		move.w		d0,d5				;d5-xxxx:A
		swap		d6				;d6-xxxx:Bsh
		swap		d0				;d0-A:xxxx
		move.w		d1,d7				;d7-new last A:new last B
		move.w		d5,d0				;d0-A:A
		rol.l		d6,d1				;shift B
		
		move.w		(a3),d2				;d2-xxxx:C
		move.w		d1,d5				;d5-xxxx:B
		move.l		d7,a5				;a5-last A:B
		swap		d1				;d1-B:xxxx
		
		move.l		(w_Amod,a0),d4			;d4-amod:bmod
		move.w		d5,d1				;d1-B:B
		move.w		d2,d6				;d6-xxxx:C
		sub.w		(w_Cmod,a0),a3			;next C
		swap		d2				;d2-C:xxxx
		sub.w		d4,a2				;next B
		move.w		d6,d2				;d2-C:C
		swap		d4				;d4-xxxx:amod
		not.w		d2				;d2-C:~C
		sub.w		d4,a1				;next A

		movem.l		(s_Mintstore,a0),d4-d7		;fetch mint
			
		and.l		d0,d6
		and.l		d0,d7
		
		and.l		d1,d5
		not.l		d0
		and.l		d1,d7
		
		and.l		d0,d4
		not.l		d1
		and.l		d0,d5

		or.l		d6,d4
		or.l		d5,d7
		and.l		d1,d4
		or.l		d7,d4
		and.l		d2,d4
		move.w		d4,d5
		swap		d4
		or.w		d5,d4				;d4-D
		
		move.w		d4,-(a4)			;write...
		
		moveq		#-1,d7				;d7-xxxx:ffff
		
		subq.l		#$01,d3
		bhi		dmainword			;--> not last word
		bcs.s		dnextrow			;--> done and dusted
		
		move.w		(w_ALWM,a0),d7			;d7-xxxx:Alwm
		bra		dmainword

dnextrow:	move.l		(w_CRmod,a0),d0			;d0-crmod:brmod
		move.l		(w_ARmod,a0),d1			;d1-armod:drmod
		sub.w		d0,a2
		swap		d0
		sub.w		d0,a3
		sub.w		d1,a4
		swap		d1
		sub.w		d1,a1
		
		subq.l		#$01,(l_Rows,a0)
		bpl		drowloop
		
		subq.l		#$02,a4				;readjust D
		
		rts
		
		
